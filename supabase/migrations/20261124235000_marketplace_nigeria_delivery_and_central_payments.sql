alter table public.marketplace_orders add column if not exists delivery_lga text;
CREATE OR REPLACE FUNCTION public.marketplace_place_order_v2(p_recipient_name text, p_recipient_phone text, p_delivery_address text, p_delivery_city text, p_delivery_lga text, p_delivery_state text, p_delivery_country text DEFAULT 'Nigeria'::text, p_buyer_note text DEFAULT NULL::text, p_payment_method text DEFAULT 'bank_transfer'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user uuid := auth.uid();
  v_cart uuid;
  v_order uuid;
  v_item record;
  v_subtotal bigint := 0;
  v_order_number text;
  v_payment_method text := lower(trim(coalesce(p_payment_method, '')));
begin
  if v_user is null then raise exception 'Sign in before checkout'; end if;
  if char_length(trim(coalesce(p_recipient_name,''))) not between 2 and 100 then
    raise exception 'Enter the recipient name';
  end if;
  if char_length(trim(coalesce(p_recipient_phone,''))) not between 7 and 25 then
    raise exception 'Enter a valid phone number';
  end if;
  if char_length(trim(coalesce(p_delivery_address,''))) not between 5 and 500 then
    raise exception 'Enter a delivery address';
  end if;
  if char_length(trim(coalesce(p_delivery_city,''))) not between 2 and 100 then
    raise exception 'Enter the delivery city';
  end if;
  if char_length(trim(coalesce(p_delivery_lga,''))) not between 2 and 100 then
    raise exception 'Choose the delivery LGA';
  end if;
  if char_length(trim(coalesce(p_delivery_state,''))) not between 2 and 100 then
    raise exception 'Enter the state';
  end if;
  if p_buyer_note is not null and char_length(p_buyer_note) > 500 then
    raise exception 'Order note is too long';
  end if;
  if v_payment_method not in ('bank_transfer','ussd','cash_on_delivery') then
    raise exception 'Choose a supported payment method';
  end if;

  if v_payment_method='bank_transfer' and not exists (
    select 1 from public.payment_settings ps where ps.id=true and ps.bank_transfer_enabled=true
      and nullif(trim(ps.bank_name),'') is not null and nullif(trim(ps.account_name),'') is not null
      and nullif(trim(ps.account_number),'') is not null
  ) then raise exception 'CreatorVerse bank transfer is not configured'; end if;
  if v_payment_method='ussd' and not exists (
    select 1 from public.payment_settings ps where ps.id=true and ps.ussd_enabled=true
  ) then raise exception 'USSD payment is not enabled'; end if;

  select c.id into v_cart
  from public.marketplace_carts c
  where c.user_id = v_user
  for update;
  if v_cart is null then raise exception 'Your cart is empty'; end if;

  -- Lock every cart/listing row and validate stock and seller eligibility before creating the order.
  for v_item in
    select ci.listing_id, ci.quantity, l.title, l.price_ngn, l.listing_type,
           l.quantity_available, l.seller_id, l.status, s.status as seller_status
    from public.marketplace_cart_items ci
    join public.marketplace_listings l on l.id = ci.listing_id
    join public.marketplace_sellers s on s.id = l.seller_id
    where ci.cart_id = v_cart
    order by l.id
    for update of ci, l
  loop
    if v_item.status <> 'published' or v_item.seller_status <> 'verified' then
      raise exception 'A product in your cart is no longer available';
    end if;
    if v_item.listing_type in ('service','rental') then
      raise exception 'Services and rentals must be arranged with the seller before checkout';
    end if;
    if v_item.quantity > v_item.quantity_available then
      raise exception 'Insufficient stock for %', v_item.title;
    end if;
    if v_item.listing_type <> 'free' and (v_item.price_ngn is null or v_item.price_ngn < 0) then
      raise exception 'The seller has not set a valid price for %', v_item.title;
    end if;
    v_subtotal := v_subtotal + (case when v_item.listing_type = 'free' then 0 else v_item.price_ngn end) * v_item.quantity;
  end loop;

  if not exists(select 1 from public.marketplace_cart_items ci where ci.cart_id = v_cart) then
    raise exception 'Your cart is empty';
  end if;
  if v_subtotal > 2000000000 then raise exception 'Order total is above the supported limit'; end if;

  v_order_number := 'CV-' || to_char(now(), 'YYYYMMDD') || '-' ||
    upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  insert into public.marketplace_orders(
    order_number, buyer_id, status, payment_method, payment_status,
    subtotal_ngn, delivery_fee_ngn, total_ngn,
    recipient_name, recipient_phone, delivery_address,
    delivery_city, delivery_lga, delivery_state, delivery_country, buyer_note
  ) values (
    v_order_number, v_user,
    case when v_payment_method = 'cash_on_delivery' then 'processing' else 'pending_payment' end,
    v_payment_method, 'pending',
    v_subtotal::integer, 0, v_subtotal::integer,
    trim(p_recipient_name), trim(p_recipient_phone), trim(p_delivery_address),
    trim(p_delivery_city), trim(p_delivery_lga), trim(p_delivery_state), coalesce(nullif(trim(p_delivery_country),''),'Nigeria'),
    nullif(trim(coalesce(p_buyer_note,'')), '')
  ) returning id into v_order;

  for v_item in
    select ci.listing_id, ci.quantity, l.title, l.price_ngn, l.listing_type,
           l.seller_id, l.image_urls
    from public.marketplace_cart_items ci
    join public.marketplace_listings l on l.id = ci.listing_id
    where ci.cart_id = v_cart
    order by l.id
  loop
    insert into public.marketplace_order_items(
      order_id, listing_id, seller_id, title_snapshot, image_snapshot,
      unit_price_ngn, quantity, line_total_ngn
    ) values (
      v_order, v_item.listing_id, v_item.seller_id, v_item.title,
      case when jsonb_typeof(to_jsonb(v_item.image_urls)) = 'array'
        then to_jsonb(v_item.image_urls)->>0 else null end,
      case when v_item.listing_type = 'free' then 0 else v_item.price_ngn end,
      v_item.quantity,
      (case when v_item.listing_type = 'free' then 0 else v_item.price_ngn end) * v_item.quantity
    );
    update public.marketplace_listings
      set quantity_available = quantity_available - v_item.quantity,
          updated_at = now()
      where id = v_item.listing_id;
  end loop;

  insert into public.marketplace_order_events(order_id, actor_id, event_type, note)
  values (v_order, v_user, 'order_placed', 'Order placed by buyer.');

  delete from public.marketplace_cart_items where cart_id = v_cart;
  update public.marketplace_carts set updated_at = now() where id = v_cart;
  return v_order;
end;
$function$
;

revoke execute on function public.marketplace_place_order_v2(text,text,text,text,text,text,text,text,text) from public,anon;
grant execute on function public.marketplace_place_order_v2(text,text,text,text,text,text,text,text,text) to authenticated;