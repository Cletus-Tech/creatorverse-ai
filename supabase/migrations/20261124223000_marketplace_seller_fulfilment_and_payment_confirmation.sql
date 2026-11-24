-- Seller fulfilment tracking and administrator-controlled marketplace payment confirmation.
create table if not exists public.marketplace_seller_fulfilments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.marketplace_orders(id) on delete cascade,
  seller_id uuid not null references public.marketplace_sellers(id) on delete restrict,
  status text not null default 'processing' check (status in ('processing','ready_for_dispatch','shipped','delivered','cancelled')),
  carrier text check (carrier is null or char_length(carrier)<=100),
  tracking_number text check (tracking_number is null or char_length(tracking_number)<=120),
  estimated_delivery date, shipped_at timestamptz, delivered_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(order_id,seller_id)
);
create index if not exists marketplace_seller_fulfilments_seller_idx on public.marketplace_seller_fulfilments(seller_id,status,updated_at desc);
create index if not exists marketplace_seller_fulfilments_order_idx on public.marketplace_seller_fulfilments(order_id);
alter table public.marketplace_seller_fulfilments enable row level security;
grant select on public.marketplace_seller_fulfilments to authenticated;
revoke insert,update,delete on public.marketplace_seller_fulfilments from authenticated;
drop policy if exists "Order participants read seller fulfilments" on public.marketplace_seller_fulfilments;
create policy "Order participants read seller fulfilments" on public.marketplace_seller_fulfilments
for select to authenticated using (private.marketplace_user_is_order_participant(order_id,(select auth.uid())));

create or replace function public.marketplace_admin_confirm_order_payment(p_order_id uuid,p_admin_note text default null)
returns void language plpgsql security definer set search_path=''
as $$
declare v_order public.marketplace_orders%rowtype; v_seller record;
begin
 if auth.uid() is null or not coalesce(public.is_admin(),false) then raise exception 'Only marketplace administrators can confirm payment'; end if;
 select * into v_order from public.marketplace_orders where id=p_order_id for update;
 if v_order.id is null then raise exception 'Order not found'; end if;
 if v_order.status in ('cancelled','refunded') or v_order.payment_status='refunded' then raise exception 'This order is no longer active'; end if;
 update public.marketplace_orders set payment_status='confirmed',
   status=case when status='pending_payment' then 'processing' else status end,updated_at=now() where id=p_order_id;
 for v_seller in select distinct seller_id from public.marketplace_order_items where order_id=p_order_id loop
  insert into public.marketplace_seller_fulfilments(order_id,seller_id,status)
   values(p_order_id,v_seller.seller_id,'processing') on conflict(order_id,seller_id) do nothing;
 end loop;
 insert into public.marketplace_order_events(order_id,actor_id,event_type,note)
  values(p_order_id,auth.uid(),'payment_confirmed',nullif(trim(coalesce(p_admin_note,'')),''));
end;
$$;

create or replace function public.marketplace_seller_update_fulfilment(
 p_order_id uuid,p_status text,p_carrier text default null,
 p_tracking_number text default null,p_estimated_delivery date default null
)
returns void language plpgsql security definer set search_path=''
as $$
declare
 v_user uuid:=auth.uid(); v_seller uuid; v_payment text; v_old_status text;
 v_total integer; v_delivered integer; v_has_shipped boolean; v_has_ready boolean; v_global_status text;
begin
 if v_user is null then raise exception 'Sign in first'; end if;
 if p_status not in ('processing','ready_for_dispatch','shipped','delivered') then raise exception 'Invalid fulfilment status'; end if;
 if p_carrier is not null and char_length(p_carrier)>100 then raise exception 'Carrier name is too long'; end if;
 if p_tracking_number is not null and char_length(p_tracking_number)>120 then raise exception 'Tracking number is too long'; end if;
 select s.id into v_seller from public.marketplace_sellers s
  where s.user_id=v_user and s.status='verified'
  and exists(select 1 from public.marketplace_order_items oi where oi.order_id=p_order_id and oi.seller_id=s.id) limit 1;
 if v_seller is null then raise exception 'You are not a verified seller on this order'; end if;
 select payment_status into v_payment from public.marketplace_orders where id=p_order_id for update;
 if v_payment is null then raise exception 'Order not found'; end if;
 if v_payment<>'confirmed' and not exists(select 1 from public.marketplace_orders where id=p_order_id and payment_method='cash_on_delivery') then
  raise exception 'Payment must be confirmed before dispatch';
 end if;
 select status into v_old_status from public.marketplace_seller_fulfilments where order_id=p_order_id and seller_id=v_seller for update;
 if v_old_status is not null and
  (case v_old_status when 'processing' then 1 when 'ready_for_dispatch' then 2 when 'shipped' then 3 when 'delivered' then 4 else 0 end) >
  (case p_status when 'processing' then 1 when 'ready_for_dispatch' then 2 when 'shipped' then 3 when 'delivered' then 4 else 0 end) then
  raise exception 'Fulfilment status cannot move backwards';
 end if;
 insert into public.marketplace_seller_fulfilments(order_id,seller_id,status,carrier,tracking_number,estimated_delivery,shipped_at,delivered_at,updated_at)
 values(p_order_id,v_seller,p_status,nullif(trim(coalesce(p_carrier,'')),''),
  nullif(trim(coalesce(p_tracking_number,'')),''),p_estimated_delivery,
  case when p_status in ('shipped','delivered') then now() else null end,
  case when p_status='delivered' then now() else null end,now())
 on conflict(order_id,seller_id) do update set status=excluded.status,
  carrier=coalesce(excluded.carrier,marketplace_seller_fulfilments.carrier),
  tracking_number=coalesce(excluded.tracking_number,marketplace_seller_fulfilments.tracking_number),
  estimated_delivery=coalesce(excluded.estimated_delivery,marketplace_seller_fulfilments.estimated_delivery),
  shipped_at=coalesce(marketplace_seller_fulfilments.shipped_at,excluded.shipped_at),
  delivered_at=coalesce(marketplace_seller_fulfilments.delivered_at,excluded.delivered_at),updated_at=now();
 select count(*),count(*) filter(where status='delivered'),
  coalesce(bool_or(status in ('shipped','delivered')),false),coalesce(bool_or(status='ready_for_dispatch'),false)
 into v_total,v_delivered,v_has_shipped,v_has_ready
 from public.marketplace_seller_fulfilments where order_id=p_order_id;
 v_global_status:=case when v_total>0 and v_total=v_delivered then 'delivered'
  when v_has_shipped then 'shipped' when v_has_ready then 'ready_for_dispatch' else 'processing' end;
 update public.marketplace_orders set status=v_global_status,
  delivered_at=case when v_global_status='delivered' then now() else delivered_at end,updated_at=now() where id=p_order_id;
 insert into public.marketplace_order_events(order_id,actor_id,event_type,note)
  values(p_order_id,v_user,'seller_fulfilment_'||p_status,
   concat_ws(' · ',nullif(trim(coalesce(p_carrier,'')),''),nullif(trim(coalesce(p_tracking_number,'')),'')));
end;
$$;
revoke all on function public.marketplace_admin_confirm_order_payment(uuid,text) from public,anon;
revoke all on function public.marketplace_seller_update_fulfilment(uuid,text,text,text,date) from public,anon;
grant execute on function public.marketplace_admin_confirm_order_payment(uuid,text) to authenticated;
grant execute on function public.marketplace_seller_update_fulfilment(uuid,text,text,text,date) to authenticated;
