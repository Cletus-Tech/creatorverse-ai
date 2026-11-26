-- Improve duplicate-cart stock feedback without changing inventory.
create or replace function public.marketplace_add_to_cart(
  p_listing_id uuid,
  p_quantity integer default 1
)
returns uuid
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_user uuid := auth.uid();
  v_cart uuid;
  v_listing public.marketplace_listings%rowtype;
  v_seller_status text;
  v_in_cart integer := 0;
begin
  if v_user is null then raise exception 'Sign in to add items to your cart'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 99 then
    raise exception 'Choose a quantity from 1 to 99';
  end if;
  insert into public.marketplace_carts(user_id)
  values (v_user)
  on conflict (user_id) do update set updated_at = now()
  returning id into v_cart;
  perform 1 from public.marketplace_carts c
  where c.id = v_cart and c.user_id = v_user for update;
  select l.* into v_listing from public.marketplace_listings l
  where l.id = p_listing_id and l.status = 'published' for update;
  if not found then raise exception 'This listing is no longer available'; end if;
  select s.status into v_seller_status from public.marketplace_sellers s
  where s.id = v_listing.seller_id;
  if v_seller_status is distinct from 'verified' then raise exception 'This seller is not currently verified'; end if;
  if v_listing.listing_type in ('service', 'rental') then raise exception 'Services and rentals must be arranged through seller enquiries'; end if;
  if v_listing.listing_type = 'free' then p_quantity := 1; end if;
  select coalesce(i.quantity, 0) into v_in_cart from public.marketplace_cart_items i
  where i.cart_id = v_cart and i.listing_id = p_listing_id for update;
  if v_in_cart > 0 and v_in_cart >= v_listing.quantity_available then
    raise exception 'This item is already in your cart at the maximum available quantity';
  end if;
  if v_in_cart + p_quantity > v_listing.quantity_available then
    raise exception 'Only % additional item(s) are currently available',
      greatest(v_listing.quantity_available - v_in_cart, 0);
  end if;
  insert into public.marketplace_cart_items(cart_id, listing_id, quantity)
  values (v_cart, p_listing_id, p_quantity)
  on conflict (cart_id, listing_id) do update
  set quantity = public.marketplace_cart_items.quantity + excluded.quantity,
      updated_at = now();
  return v_cart;
end;
$function$;
revoke all on function public.marketplace_add_to_cart(uuid, integer) from public, anon;
grant execute on function public.marketplace_add_to_cart(uuid, integer) to authenticated;
