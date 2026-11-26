alter table public.marketplace_orders add column if not exists payment_expires_at timestamptz;

create index if not exists marketplace_orders_pending_payment_expiry_idx
  on public.marketplace_orders(payment_expires_at)
  where status='pending_payment' and payment_status='pending'
    and payment_method in ('bank_transfer','ussd') and payment_expires_at is not null;

create or replace function private.cv_set_marketplace_payment_expiry()
returns trigger language plpgsql security definer set search_path = ''
as $function$
declare v_minutes integer;
begin
  if new.payment_method in ('bank_transfer','ussd') and new.status='pending_payment' and new.payment_status='pending' then
    select greatest(5,least(coalesce(ps.payment_window_minutes,30),1440)) into v_minutes
    from public.payment_settings ps where ps.id=true;
    new.payment_expires_at := now() + make_interval(mins => coalesce(v_minutes,30));
  else
    new.payment_expires_at := null;
  end if;
  return new;
end;
$function$;

drop trigger if exists cv_set_marketplace_payment_expiry on public.marketplace_orders;
create trigger cv_set_marketplace_payment_expiry
before insert or update of payment_method,status,payment_status on public.marketplace_orders
for each row execute function private.cv_set_marketplace_payment_expiry();
revoke all on function private.cv_set_marketplace_payment_expiry() from public,anon,authenticated;

create or replace function private.cv_expire_stale_marketplace_orders()
returns integer language plpgsql security definer set search_path = ''
as $function$
declare v_order record; v_item record; v_expired integer := 0;
begin
  for v_order in
    select o.id from public.marketplace_orders o
    where o.status='pending_payment' and o.payment_status='pending'
      and o.payment_method in ('bank_transfer','ussd')
      and o.payment_expires_at is not null and o.payment_expires_at <= now()
    order by o.payment_expires_at for update skip locked
  loop
    for v_item in
      select oi.listing_id,oi.quantity from public.marketplace_order_items oi
      where oi.order_id=v_order.id and oi.listing_id is not null for update
    loop
      update public.marketplace_listings
      set quantity_available=quantity_available+v_item.quantity,updated_at=now()
      where id=v_item.listing_id;
    end loop;
    update public.marketplace_orders
    set status='cancelled',payment_status='failed',cancelled_at=coalesce(cancelled_at,now()),
        payment_expires_at=null,updated_at=now()
    where id=v_order.id;
    insert into public.marketplace_order_events(order_id,actor_id,event_type,note)
    values(v_order.id,null,'payment_window_expired',
      'The payment window elapsed without confirmed payment. Reserved stock was released.');
    v_expired:=v_expired+1;
  end loop;
  return v_expired;
end;
$function$;
revoke all on function private.cv_expire_stale_marketplace_orders() from public,anon,authenticated;

select cron.schedule('cv-expire-marketplace-payment-windows','* * * * *',
  'select private.cv_expire_stale_marketplace_orders();');

create or replace function private.cv_notify_marketplace_order_event()
returns trigger language plpgsql security definer set search_path = ''
as $function$
declare v_buyer uuid; v_order_number text; v_title text; v_body text; v_seller record;
begin
  select o.buyer_id,o.order_number into v_buyer,v_order_number
  from public.marketplace_orders o where o.id=new.order_id;
  if v_buyer is null then return new; end if;
  case new.event_type
    when 'order_placed' then v_title:='New Marketplace order'; v_body:='Order '||v_order_number||' has been placed. Open your seller orders to review it.';
    when 'payment_confirmed' then v_title:='Marketplace payment confirmed'; v_body:='Payment for order '||v_order_number||' has been confirmed.';
    when 'order_cancelled' then v_title:='Marketplace order cancelled'; v_body:='Order '||v_order_number||' was cancelled and its reserved stock was released.';
    when 'payment_window_expired' then v_title:='Marketplace payment window expired'; v_body:='Payment was not confirmed in time for order '||v_order_number||'. The reserved stock has been released.';
    when 'seller_fulfilment_processing' then v_title:='Your Marketplace order is processing'; v_body:='A seller has started processing order '||v_order_number||'.';
    when 'seller_fulfilment_ready_for_dispatch' then v_title:='Your Marketplace order is ready for dispatch'; v_body:='A seller has prepared order '||v_order_number||' for dispatch.';
    when 'seller_fulfilment_shipped' then v_title:='Your Marketplace order has shipped'; v_body:='A seller has shipped order '||v_order_number||'. Check the tracking details.';
    when 'seller_fulfilment_delivered' then v_title:='Marketplace order delivered'; v_body:='A seller has marked order '||v_order_number||' as delivered.';
    else v_title:='Marketplace order updated'; v_body:='There is an update to order '||v_order_number||'.';
  end case;
  if new.actor_id is distinct from v_buyer then
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_buyer,new.actor_id,'marketplace_order',v_title,v_body,
      'marketplace-commerce.html?view=order&id='||new.order_id::text,'marketplace_order',new.order_id);
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
        when 'payment_window_expired' then 'Unpaid Marketplace order expired'
        else 'Marketplace order updated' end,
      case new.event_type when 'order_placed' then 'Order '||v_order_number||' is waiting in your seller orders.'
        when 'payment_confirmed' then 'Payment for order '||v_order_number||' has been confirmed. You can continue fulfilment.'
        when 'order_cancelled' then 'Order '||v_order_number||' was cancelled.'
        when 'payment_window_expired' then 'Order '||v_order_number||' expired unpaid. Its reserved stock is available again.'
        else 'There is an update to order '||v_order_number||'.' end,
      'marketplace-commerce.html?view=seller-orders','marketplace_order',new.order_id);
  end loop;
  return new;
end;
$function$;
revoke all on function private.cv_notify_marketplace_order_event() from public,anon,authenticated;
