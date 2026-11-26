-- Marketplace payout controls, seller payout ledger and multi-seller delivery aggregation.
-- All money transfers remain manual; this records verified transfers and their references.

create or replace function public.marketplace_submit_seller_application_v2(
  p_display_name text,
  p_seller_type text,
  p_institution text,
  p_campus text,
  p_bio text,
  p_bank_name text,
  p_account_name text,
  p_account_number text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_seller uuid;
begin
  if v_user is null then raise exception 'Sign in to apply as a seller'; end if;
  if char_length(trim(coalesce(p_display_name,''))) not between 2 and 80 then
    raise exception 'Enter a seller or business name between 2 and 80 characters';
  end if;
  if coalesce(p_seller_type,'') not in ('student','campus_vendor','service_provider') then
    raise exception 'Choose a valid seller type';
  end if;
  if char_length(trim(coalesce(p_bank_name,''))) not between 2 and 100 then
    raise exception 'Enter your bank or financial institution';
  end if;
  if char_length(trim(coalesce(p_account_name,''))) not between 2 and 100 then
    raise exception 'Enter the bank account name';
  end if;
  if trim(coalesce(p_account_number,'')) !~ '^[0-9]{10}$' then
    raise exception 'Enter a valid 10-digit Nigerian bank account number';
  end if;
  if char_length(coalesce(p_bio,'')) > 500 then raise exception 'Seller description is too long'; end if;
  if exists(select 1 from public.marketplace_sellers where user_id=v_user) then
    raise exception 'A seller application already exists for this account';
  end if;

  insert into public.marketplace_sellers(user_id,display_name,seller_type,institution,campus,bio)
  values(v_user,trim(p_display_name),p_seller_type,
    nullif(trim(coalesce(p_institution,'')), ''),
    nullif(trim(coalesce(p_campus,'')), ''),
    nullif(trim(coalesce(p_bio,'')), ''))
  returning id into v_seller;

  insert into public.marketplace_seller_payout_accounts(seller_id,user_id,bank_name,account_name,account_number)
  values(v_seller,v_user,trim(p_bank_name),trim(p_account_name),trim(p_account_number));
  return v_seller;
end;
$$;

create or replace function public.marketplace_save_seller_payout_account(
  p_bank_name text,
  p_bank_code text,
  p_account_name text,
  p_account_number text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_seller uuid;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  if char_length(trim(coalesce(p_bank_name,''))) not between 2 and 100 then
    raise exception 'Enter your bank or financial institution';
  end if;
  if char_length(trim(coalesce(p_account_name,''))) not between 2 and 100 then
    raise exception 'Enter the bank account name';
  end if;
  if trim(coalesce(p_account_number,'')) !~ '^[0-9]{10}$' then
    raise exception 'Enter a valid 10-digit Nigerian bank account number';
  end if;
  if p_bank_code is not null and char_length(trim(p_bank_code)) > 20 then
    raise exception 'Bank code is too long';
  end if;

  select id into v_seller from public.marketplace_sellers where user_id=v_user;
  if v_seller is null then raise exception 'Create a seller profile before adding payout details'; end if;

  insert into public.marketplace_seller_payout_accounts(
    seller_id,user_id,bank_name,bank_code,account_name,account_number,verified_at,verified_by
  ) values (
    v_seller,v_user,trim(p_bank_name),nullif(trim(coalesce(p_bank_code,'')), ''),
    trim(p_account_name),trim(p_account_number),null,null
  )
  on conflict(seller_id) do update set
    bank_name=excluded.bank_name,
    bank_code=excluded.bank_code,
    account_name=excluded.account_name,
    account_number=excluded.account_number,
    verified_at=null,
    verified_by=null,
    updated_at=now();
end;
$$;

create or replace function public.marketplace_admin_verify_seller_payout_account(
  p_seller_id uuid,
  p_verified boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not coalesce(public.is_admin(),false) then
    raise exception 'Only marketplace administrators can verify seller payout accounts';
  end if;
  update public.marketplace_seller_payout_accounts
  set verified_at=case when p_verified then now() else null end,
      verified_by=case when p_verified then auth.uid() else null end,
      updated_at=now()
  where seller_id=p_seller_id;
  if not found then raise exception 'Seller payout account not found'; end if;
end;
$$;

create table if not exists public.marketplace_seller_payouts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.marketplace_sellers(id) on delete restrict,
  order_id uuid not null references public.marketplace_orders(id) on delete restrict,
  amount_ngn integer not null check (amount_ngn > 0),
  transfer_reference text not null check (char_length(trim(transfer_reference)) between 2 and 120),
  admin_note text check (admin_note is null or char_length(admin_note) <= 500),
  created_by uuid references auth.users(id) on delete set null,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint marketplace_seller_payouts_seller_order_key unique(seller_id,order_id)
);

alter table public.marketplace_seller_payouts enable row level security;
drop policy if exists "Marketplace admins manage seller payouts" on public.marketplace_seller_payouts;
drop policy if exists "Sellers read own payout history" on public.marketplace_seller_payouts;
create policy "Marketplace admins manage seller payouts"
on public.marketplace_seller_payouts for all to authenticated
using (coalesce(public.is_admin(),false))
with check (coalesce(public.is_admin(),false));
create policy "Sellers read own payout history"
on public.marketplace_seller_payouts for select to authenticated
using (exists (
  select 1 from public.marketplace_sellers s
  where s.id=marketplace_seller_payouts.seller_id and s.user_id=auth.uid()
));

grant select on public.marketplace_seller_payouts to authenticated;
revoke insert, update, delete on public.marketplace_seller_payouts from anon, authenticated;

-- Sellers can read their own payout destination, but only the security-definer RPCs
-- above may create or change bank details or verification fields.
grant select on public.marketplace_seller_payout_accounts to authenticated;
revoke insert, update, delete on public.marketplace_seller_payout_accounts from anon, authenticated;

create or replace function public.marketplace_admin_record_seller_payout(
  p_seller_id uuid,
  p_order_id uuid,
  p_amount_ngn integer,
  p_transfer_reference text,
  p_admin_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order_status text;
  v_verified_at timestamptz;
  v_gross bigint;
  v_payout uuid;
begin
  if auth.uid() is null or not coalesce(public.is_admin(),false) then
    raise exception 'Only marketplace administrators can record seller payouts';
  end if;
  if p_amount_ngn is null or p_amount_ngn < 1 then raise exception 'Enter a payout amount greater than zero'; end if;
  if char_length(trim(coalesce(p_transfer_reference,''))) not between 2 and 120 then
    raise exception 'Enter the bank transfer reference';
  end if;
  if p_admin_note is not null and char_length(p_admin_note)>500 then raise exception 'Payout note is too long'; end if;

  select status into v_order_status from public.marketplace_orders where id=p_order_id for update;
  if v_order_status is distinct from 'delivered' then
    raise exception 'Seller payout can only be recorded after the order is fully delivered';
  end if;

  select verified_at into v_verified_at
  from public.marketplace_seller_payout_accounts
  where seller_id=p_seller_id for update;
  if v_verified_at is null then raise exception 'Verify the seller payout account before recording payment'; end if;

  select coalesce(sum(line_total_ngn),0) into v_gross
  from public.marketplace_order_items
  where order_id=p_order_id and seller_id=p_seller_id;
  if v_gross < 1 then raise exception 'No payable seller items were found for this order'; end if;
  if p_amount_ngn > v_gross then raise exception 'Payout cannot exceed the seller order value of ₦% ',v_gross; end if;

  insert into public.marketplace_seller_payouts(
    seller_id,order_id,amount_ngn,transfer_reference,admin_note,created_by
  ) values (
    p_seller_id,p_order_id,p_amount_ngn,trim(p_transfer_reference),
    nullif(trim(coalesce(p_admin_note,'')),''),auth.uid()
  ) returning id into v_payout;
  return v_payout;
exception
  when unique_violation then
    raise exception 'A payout has already been recorded for this seller and order';
end;
$$;

create or replace function public.marketplace_seller_update_fulfilment(
  p_order_id uuid,
  p_status text,
  p_carrier text default null,
  p_tracking_number text default null,
  p_estimated_delivery date default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid:=auth.uid();
  v_seller uuid;
  v_payment text;
  v_order_status text;
  v_old_status text;
  v_expected integer;
  v_total integer;
  v_delivered integer;
  v_has_shipped boolean;
  v_has_ready boolean;
  v_global_status text;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  if p_status not in ('processing','ready_for_dispatch','shipped','delivered') then
    raise exception 'Invalid fulfilment status';
  end if;
  if p_carrier is not null and char_length(p_carrier)>100 then raise exception 'Carrier name is too long'; end if;
  if p_tracking_number is not null and char_length(p_tracking_number)>120 then raise exception 'Tracking number is too long'; end if;

  select s.id into v_seller
  from public.marketplace_sellers s
  where s.user_id=v_user and s.status='verified'
    and exists(select 1 from public.marketplace_order_items oi where oi.order_id=p_order_id and oi.seller_id=s.id)
  limit 1;
  if v_seller is null then raise exception 'You are not a verified seller on this order'; end if;

  select status,payment_status into v_order_status,v_payment
  from public.marketplace_orders where id=p_order_id for update;
  if v_payment is null then raise exception 'Order not found'; end if;
  if v_order_status in ('cancelled','refunded') then raise exception 'This order is no longer active'; end if;
  if v_payment<>'confirmed' and not exists(
    select 1 from public.marketplace_orders where id=p_order_id and payment_method='cash_on_delivery'
  ) then raise exception 'Payment must be confirmed before dispatch'; end if;

  select status into v_old_status from public.marketplace_seller_fulfilments
  where order_id=p_order_id and seller_id=v_seller for update;
  if v_old_status is not null then
    if (case v_old_status when 'processing' then 1 when 'ready_for_dispatch' then 2 when 'shipped' then 3 when 'delivered' then 4 else 0 end)
       > (case p_status when 'processing' then 1 when 'ready_for_dispatch' then 2 when 'shipped' then 3 when 'delivered' then 4 else 0 end) then
      raise exception 'Fulfilment status cannot move backwards';
    end if;
  end if;

  insert into public.marketplace_seller_fulfilments(
    order_id,seller_id,status,carrier,tracking_number,estimated_delivery,shipped_at,delivered_at,updated_at
  ) values(
    p_order_id,v_seller,p_status,nullif(trim(coalesce(p_carrier,'')),''),
    nullif(trim(coalesce(p_tracking_number,'')),''),p_estimated_delivery,
    case when p_status in ('shipped','delivered') then now() else null end,
    case when p_status='delivered' then now() else null end,now()
  )
  on conflict(order_id,seller_id) do update set
    status=excluded.status,
    carrier=coalesce(excluded.carrier,public.marketplace_seller_fulfilments.carrier),
    tracking_number=coalesce(excluded.tracking_number,public.marketplace_seller_fulfilments.tracking_number),
    estimated_delivery=coalesce(excluded.estimated_delivery,public.marketplace_seller_fulfilments.estimated_delivery),
    shipped_at=coalesce(public.marketplace_seller_fulfilments.shipped_at,excluded.shipped_at),
    delivered_at=coalesce(public.marketplace_seller_fulfilments.delivered_at,excluded.delivered_at),
    updated_at=now();

  select count(distinct seller_id) into v_expected
  from public.marketplace_order_items where order_id=p_order_id;
  select count(*),count(*) filter(where status='delivered'),
    coalesce(bool_or(status in ('shipped','delivered')),false),
    coalesce(bool_or(status='ready_for_dispatch'),false)
  into v_total,v_delivered,v_has_shipped,v_has_ready
  from public.marketplace_seller_fulfilments where order_id=p_order_id;

  v_global_status:=case
    when v_expected>0 and v_total>=v_expected and v_delivered>=v_expected then 'delivered'
    when v_has_shipped then 'shipped'
    when v_has_ready then 'ready_for_dispatch'
    else 'processing'
  end;

  update public.marketplace_orders
  set status=v_global_status,
      delivered_at=case when v_global_status='delivered' then now() else delivered_at end,
      updated_at=now()
  where id=p_order_id;

  insert into public.marketplace_order_events(order_id,actor_id,event_type,note)
  values(p_order_id,v_user,'seller_fulfilment_'||p_status,
    concat_ws(' · ',nullif(trim(coalesce(p_carrier,'')),''),nullif(trim(coalesce(p_tracking_number,'')),'')));
end;
$$;

revoke all on function public.marketplace_submit_seller_application_v2(text,text,text,text,text,text,text,text) from public, anon;
grant execute on function public.marketplace_submit_seller_application_v2(text,text,text,text,text,text,text,text) to authenticated;
revoke all on function public.marketplace_save_seller_payout_account(text,text,text,text) from public, anon;
grant execute on function public.marketplace_save_seller_payout_account(text,text,text,text) to authenticated;
revoke all on function public.marketplace_admin_verify_seller_payout_account(uuid,boolean) from public, anon;
grant execute on function public.marketplace_admin_verify_seller_payout_account(uuid,boolean) to authenticated;
revoke all on function public.marketplace_admin_record_seller_payout(uuid,uuid,integer,text,text) from public, anon;
grant execute on function public.marketplace_admin_record_seller_payout(uuid,uuid,integer,text,text) to authenticated;
revoke all on function public.marketplace_seller_update_fulfilment(uuid,text,text,text,date) from public, anon;
grant execute on function public.marketplace_seller_update_fulfilment(uuid,text,text,text,date) to authenticated;
