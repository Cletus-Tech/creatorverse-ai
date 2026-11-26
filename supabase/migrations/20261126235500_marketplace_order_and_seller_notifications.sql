create or replace function private.cv_notify_marketplace_order_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_buyer uuid;
  v_order_number text;
  v_title text;
  v_body text;
  v_seller record;
begin
  select o.buyer_id, o.order_number into v_buyer, v_order_number
  from public.marketplace_orders o where o.id = new.order_id;
  if v_buyer is null then return new; end if;

  case new.event_type
    when 'order_placed' then v_title := 'New Marketplace order'; v_body := 'Order ' || v_order_number || ' has been placed. Open your seller orders to review it.';
    when 'payment_confirmed' then v_title := 'Marketplace payment confirmed'; v_body := 'Payment for order ' || v_order_number || ' has been confirmed.';
    when 'order_cancelled' then v_title := 'Marketplace order cancelled'; v_body := 'Order ' || v_order_number || ' was cancelled and its reserved stock was released.';
    when 'seller_fulfilment_processing' then v_title := 'Your Marketplace order is processing'; v_body := 'A seller has started processing order ' || v_order_number || '.';
    when 'seller_fulfilment_ready_for_dispatch' then v_title := 'Your Marketplace order is ready for dispatch'; v_body := 'A seller has prepared order ' || v_order_number || ' for dispatch.';
    when 'seller_fulfilment_shipped' then v_title := 'Your Marketplace order has shipped'; v_body := 'A seller has shipped order ' || v_order_number || '. Check the tracking details.';
    when 'seller_fulfilment_delivered' then v_title := 'Marketplace order delivered'; v_body := 'A seller has marked order ' || v_order_number || ' as delivered.';
    else v_title := 'Marketplace order updated'; v_body := 'There is an update to order ' || v_order_number || '.';
  end case;

  if new.actor_id is distinct from v_buyer then
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_buyer,new.actor_id,'marketplace_order',v_title,v_body,
      'marketplace-commerce.html?view=order&id=' || new.order_id::text,'marketplace_order',new.order_id);
  end if;

  for v_seller in
    select distinct s.user_id from public.marketplace_order_items oi
    join public.marketplace_sellers s on s.id=oi.seller_id
    where oi.order_id=new.order_id and s.user_id is not null
      and s.user_id is distinct from new.actor_id and s.user_id is distinct from v_buyer
  loop
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_seller.user_id,new.actor_id,'marketplace_order',
      case new.event_type when 'order_placed' then 'You received a Marketplace order'
        when 'payment_confirmed' then 'Buyer payment confirmed'
        when 'order_cancelled' then 'A Marketplace order was cancelled'
        else 'Marketplace order updated' end,
      case new.event_type when 'order_placed' then 'Order ' || v_order_number || ' is waiting in your seller orders.'
        when 'payment_confirmed' then 'Payment for order ' || v_order_number || ' has been confirmed. You can continue fulfilment.'
        when 'order_cancelled' then 'Order ' || v_order_number || ' was cancelled.'
        else 'There is an update to order ' || v_order_number || '.' end,
      'marketplace-commerce.html?view=seller-orders','marketplace_order',new.order_id);
  end loop;
  return new;
end;
$function$;

drop trigger if exists cv_notify_marketplace_order_event on public.marketplace_order_events;
create trigger cv_notify_marketplace_order_event after insert on public.marketplace_order_events
for each row execute function private.cv_notify_marketplace_order_event();

create or replace function private.cv_notify_marketplace_seller_status()
returns trigger language plpgsql security definer set search_path = ''
as $function$
declare v_title text; v_body text;
begin
  if new.status is not distinct from old.status then return new; end if;
  if new.status='verified' then
    v_title:='Your Marketplace seller account is verified';
    v_body:='You can now publish listings. New listings from verified sellers go live automatically.';
  elsif new.status='rejected' then
    v_title:='Your Marketplace seller application needs attention';
    v_body:=coalesce(nullif(left(new.review_note,300),''),'Open your seller workspace to review the administrator feedback.');
  elsif new.status='suspended' then
    v_title:='Your Marketplace seller account is suspended';
    v_body:=coalesce(nullif(left(new.review_note,300),''),'Contact CreatorVerse support if you believe this is an error.');
  else return new;
  end if;
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  values(new.user_id,new.reviewed_by,'marketplace_seller',v_title,v_body,'marketplace.html','marketplace_seller',new.id);
  return new;
end;
$function$;

drop trigger if exists cv_notify_marketplace_seller_status on public.marketplace_sellers;
create trigger cv_notify_marketplace_seller_status after update of status on public.marketplace_sellers
for each row execute function private.cv_notify_marketplace_seller_status();

create or replace function private.cv_notify_marketplace_seller_payout()
returns trigger language plpgsql security definer set search_path = ''
as $function$
declare v_user uuid; v_order_number text;
begin
  select s.user_id into v_user from public.marketplace_sellers s where s.id=new.seller_id;
  select o.order_number into v_order_number from public.marketplace_orders o where o.id=new.order_id;
  if v_user is not null then
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_user,new.created_by,'marketplace_payout','Marketplace payout recorded',
      'A payout of ₦' || new.amount_ngn::text || ' for order ' || coalesce(v_order_number,new.order_id::text) || ' has been recorded.',
      'marketplace-commerce.html?view=seller-payout','marketplace_payout',new.id);
  end if;
  return new;
end;
$function$;

drop trigger if exists cv_notify_marketplace_seller_payout on public.marketplace_seller_payouts;
create trigger cv_notify_marketplace_seller_payout after insert on public.marketplace_seller_payouts
for each row execute function private.cv_notify_marketplace_seller_payout();
