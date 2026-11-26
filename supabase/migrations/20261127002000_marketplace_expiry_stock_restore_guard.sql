create or replace function public.marketplace_guard_listing()
returns trigger language plpgsql security definer
set search_path to 'pg_catalog','public','auth'
as $function$
declare v_is_admin boolean; v_seller_owner uuid; v_seller_status text;
begin
  if tg_op='UPDATE' and coalesce(current_setting('app.marketplace_internal_stock_restore',true),'')='on' then
    if (to_jsonb(new)-'quantity_available'-'updated_at') is distinct from
       (to_jsonb(old)-'quantity_available'-'updated_at') then
      raise exception 'Internal Marketplace stock restoration may only change available quantity';
    end if;
    new.updated_at:=now();
    return new;
  end if;
  v_is_admin:=coalesce(public.is_admin(),false);
  if tg_op='INSERT' then
    select user_id,status into v_seller_owner,v_seller_status from public.marketplace_sellers where id=new.seller_id;
    if auth.uid() is null or v_seller_owner is distinct from auth.uid() then raise exception 'You can only create listings for your own seller profile'; end if;
    if v_seller_status <> 'verified' then raise exception 'Your seller profile must be verified before publishing listings'; end if;
    if new.title is null or char_length(trim(new.title))=0 then raise exception 'Add a product title before publishing'; end if;
    if not exists(select 1 from public.marketplace_categories c where c.id=new.category_id and c.active) then raise exception 'Choose an active marketplace category'; end if;
    new.status:='published'; new.reviewed_by:=null; new.reviewed_at:=null; new.moderation_note:=null; new.published_at:=now();
  elsif not v_is_admin then
    select user_id,status into v_seller_owner,v_seller_status from public.marketplace_sellers where id=old.seller_id;
    if v_seller_owner is distinct from auth.uid() then raise exception 'You do not own this listing'; end if;
    if v_seller_status <> 'verified' then raise exception 'Your seller account is not currently active'; end if;
    if new.seller_id is distinct from old.seller_id or new.status is distinct from old.status
      or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at
      or new.moderation_note is distinct from old.moderation_note or new.published_at is distinct from old.published_at then
      raise exception 'Listing ownership and moderation fields cannot be changed by sellers';
    end if;
    if new.title is null or char_length(trim(new.title))=0 then raise exception 'Add a product title before saving'; end if;
    if not exists(select 1 from public.marketplace_categories c where c.id=new.category_id and c.active) then raise exception 'Choose an active marketplace category'; end if;
    if old.status in ('draft','rejected','pending_review') then new.status:='published'; new.published_at:=coalesce(old.published_at,now()); end if;
  else
    if new.status='published' and old.status is distinct from 'published' then
      new.reviewed_by:=auth.uid(); new.reviewed_at:=now(); new.published_at:=now();
    end if;
  end if;
  new.updated_at:=now();
  return new;
end;
$function$;

create or replace function private.cv_expire_stale_marketplace_orders()
returns integer language plpgsql security definer set search_path = ''
as $function$
declare v_order record; v_item record; v_expired integer:=0;
  v_previous_restore_setting text:=coalesce(current_setting('app.marketplace_internal_stock_restore',true),'');
begin
  perform pg_catalog.set_config('app.marketplace_internal_stock_restore','on',true);
  for v_order in
    select o.id from public.marketplace_orders o
    where o.status='pending_payment' and o.payment_status='pending'
      and o.payment_method in ('bank_transfer','ussd')
      and o.payment_expires_at is not null and o.payment_expires_at<=now()
    order by o.payment_expires_at for update skip locked
  loop
    for v_item in select oi.listing_id,oi.quantity from public.marketplace_order_items oi
      where oi.order_id=v_order.id and oi.listing_id is not null for update
    loop
      update public.marketplace_listings set quantity_available=quantity_available+v_item.quantity,updated_at=now()
      where id=v_item.listing_id;
    end loop;
    update public.marketplace_orders set status='cancelled',payment_status='failed',
      cancelled_at=coalesce(cancelled_at,now()),payment_expires_at=null,updated_at=now()
    where id=v_order.id;
    insert into public.marketplace_order_events(order_id,actor_id,event_type,note)
    values(v_order.id,null,'payment_window_expired',
      'The payment window elapsed without confirmed payment. Reserved stock was released.');
    v_expired:=v_expired+1;
  end loop;
  perform pg_catalog.set_config('app.marketplace_internal_stock_restore',v_previous_restore_setting,true);
  return v_expired;
exception when others then
  perform pg_catalog.set_config('app.marketplace_internal_stock_restore',v_previous_restore_setting,true);
  raise;
end;
$function$;
revoke all on function private.cv_expire_stale_marketplace_orders() from public,anon,authenticated;
