-- Applied to the CreatorVerse production project on 2026-11-16.
-- Hardens manual payment approvals, preserves financial records, and adds audit history/receipts.

alter table public.payment_orders
  add column if not exists receipt_number text,
  add column if not exists receipt_issued_at timestamptz,
  add column if not exists receipt_course_title text,
  add column if not exists receipt_payer_name text;

create unique index if not exists payment_orders_receipt_number_uidx
  on public.payment_orders(receipt_number) where receipt_number is not null;

create unique index if not exists payment_orders_transfer_reference_uidx
  on public.payment_orders (lower(btrim(transfer_reference)))
  where transfer_reference is not null and btrim(transfer_reference) <> ''
    and status in ('proof_submitted','confirmed');

alter table public.payment_orders drop constraint if exists payment_orders_user_id_fkey;
alter table public.payment_orders add constraint payment_orders_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete restrict;
alter table public.payment_orders drop constraint if exists payment_orders_course_id_fkey;
alter table public.payment_orders add constraint payment_orders_course_id_fkey
  foreign key (course_id) references public.courses(id) on delete restrict;

create table if not exists public.payment_order_events (
  id bigint generated always as identity primary key,
  payment_order_id uuid not null references public.payment_orders(id) on delete restrict,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null check (event_type in ('created','proof_submitted','confirmed','rejected','admin_note_updated')),
  from_status text,
  to_status text,
  note text,
  created_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);
create index if not exists payment_order_events_order_created_idx
  on public.payment_order_events(payment_order_id, created_at desc);
alter table public.payment_order_events enable row level security;
revoke all on public.payment_order_events from anon, authenticated;
grant select on public.payment_order_events to authenticated;
drop policy if exists "payment events admin read" on public.payment_order_events;
create policy "payment events admin read" on public.payment_order_events
  for select to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role in ('admin','super_admin')
  ));

revoke all on table public.payment_orders from anon, authenticated;
grant select, insert, update on table public.payment_orders to authenticated;
revoke all on table public.payment_settings from anon, authenticated;
grant select, update on table public.payment_settings to authenticated;

drop policy if exists "admins manage payment orders" on public.payment_orders;
drop policy if exists "admins update payment orders" on public.payment_orders;
create policy "admins update payment orders" on public.payment_orders
  for update to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role in ('admin','super_admin')
  ))
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role in ('admin','super_admin')
  ));

drop policy if exists "payment settings admin update" on public.payment_settings;
create policy "payment settings admin update" on public.payment_settings
  for update to authenticated
  using (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role in ('admin','super_admin')
  ))
  with check (exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role in ('admin','super_admin')
  ));

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('payment-proofs','payment-proofs',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

drop policy if exists "payment proof upload own" on storage.objects;
create policy "payment proof upload own" on storage.objects
  for insert to authenticated
  with check (bucket_id='payment-proofs' and (storage.foldername(name))[1]=(select auth.uid())::text);

drop policy if exists "payment proof read own or admin" on storage.objects;
create policy "payment proof read own or admin" on storage.objects
  for select to authenticated
  using (
    bucket_id='payment-proofs' and (
      (storage.foldername(name))[1]=(select auth.uid())::text
      or exists (select 1 from public.profiles p
        where p.id=(select auth.uid()) and p.role in ('admin','super_admin'))
    )
  );

create or replace function public.cv_payment_order_guard()
returns trigger language plpgsql security definer set search_path=''
as $function$
declare
  cfg public.payment_settings%rowtype;
  actual_price integer;
  admin_user boolean;
  course_title text;
  payer_name text;
begin
  select * into cfg from public.payment_settings where id=true;
  admin_user := exists(select 1 from public.profiles p
    where p.id=auth.uid() and p.role in ('admin','super_admin'));

  if tg_op='INSERT' then
    if auth.uid() is null or new.user_id<>auth.uid() then raise exception 'Invalid payment owner'; end if;
    select c.price_ngn into actual_price from public.courses c
      where c.id=new.course_id and c.published=true;
    if actual_price is null or actual_price<=0 then raise exception 'This course is not available for paid checkout'; end if;
    if new.method='bank_transfer' and (
      not cfg.bank_transfer_enabled or coalesce(cfg.bank_name,'')=''
      or coalesce(cfg.account_name,'')='' or coalesce(cfg.account_number,'')=''
    ) then raise exception 'Bank transfer is not configured yet'; end if;
    if new.method='ussd' and (not cfg.ussd_enabled or coalesce(cfg.ussd_instructions,'')='')
      then raise exception 'USSD payment is not configured yet'; end if;
    if new.method='international' then raise exception 'International payments are not available yet'; end if;
    new.amount_ngn:=actual_price;
    new.currency:='NGN';
    new.status:='pending';
    new.reference:='CV-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12));
    new.expires_at:=now()+make_interval(mins=>cfg.payment_window_minutes);
    new.proof_url:=null;
    new.transfer_reference:=null;
    new.admin_note:=null;
    new.confirmed_at:=null;
    new.receipt_number:=null;
    new.receipt_issued_at:=null;
    new.receipt_course_title:=null;
    new.receipt_payer_name:=null;
    new.updated_at:=now();
    return new;
  end if;

  if not admin_user then
    if new.user_id is distinct from old.user_id or new.course_id is distinct from old.course_id
      or new.amount_ngn is distinct from old.amount_ngn or new.currency is distinct from old.currency
      or new.method is distinct from old.method or new.reference is distinct from old.reference
      or new.expires_at is distinct from old.expires_at or new.admin_note is distinct from old.admin_note
      or new.confirmed_at is distinct from old.confirmed_at
      or new.receipt_number is distinct from old.receipt_number
      or new.receipt_issued_at is distinct from old.receipt_issued_at
      or new.receipt_course_title is distinct from old.receipt_course_title
      or new.receipt_payer_name is distinct from old.receipt_payer_name
      or new.created_at is distinct from old.created_at then raise exception 'Payment details are protected'; end if;
    if old.status<>'pending' or new.status<>'proof_submitted' or old.expires_at<=now()
      then raise exception 'Only an active payment request can receive a transfer submission'; end if;
    if coalesce(length(btrim(new.transfer_reference)),0)<4
      then raise exception 'Enter the bank or USSD transaction reference'; end if;
    if new.proof_url is not null and new.proof_url not like new.user_id::text||'/'||old.id::text||'/%'
      then raise exception 'Payment proof must belong to this payment request'; end if;
    new.updated_at:=now();
    return new;
  end if;

  if new.user_id is distinct from old.user_id or new.course_id is distinct from old.course_id
    or new.amount_ngn is distinct from old.amount_ngn or new.currency is distinct from old.currency
    or new.method is distinct from old.method or new.reference is distinct from old.reference
    or new.expires_at is distinct from old.expires_at
    or new.transfer_reference is distinct from old.transfer_reference
    or new.proof_url is distinct from old.proof_url or new.created_at is distinct from old.created_at
    then raise exception 'Original payment details cannot be edited by reviewers'; end if;

  if new.status is distinct from old.status then
    if old.status<>'proof_submitted' or new.status not in ('confirmed','rejected')
      then raise exception 'Only submitted payment proofs can be confirmed or rejected'; end if;
    if new.status='confirmed' then
      if coalesce(length(btrim(old.transfer_reference)),0)<4
        then raise exception 'A valid transfer reference is required before confirmation'; end if;
      new.confirmed_at:=now();
      new.receipt_issued_at:=now();
      new.receipt_number:='CVR-'||to_char(now() at time zone 'utc','YYYYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
      select c.title into course_title from public.courses c where c.id=old.course_id;
      select p.full_name into payer_name from public.profiles p where p.id=old.user_id;
      new.receipt_course_title:=coalesce(course_title,'CreatorVerse course');
      new.receipt_payer_name:=coalesce(nullif(btrim(payer_name),''),'CreatorVerse learner');
    else
      if coalesce(length(btrim(new.admin_note)),0)=0 then raise exception 'Add a reason before rejecting a payment'; end if;
    end if;
  end if;
  new.updated_at:=now();
  return new;
end
$function$;
revoke all on function public.cv_payment_order_guard() from public,anon,authenticated;

create or replace function public.cv_payment_order_audit()
returns trigger language plpgsql security definer set search_path=''
as $function$
declare v_type text; v_from text; v_to text;
begin
  if tg_op='INSERT' then v_type:='created'; v_from:=null; v_to:=new.status;
  else
    if new.status is distinct from old.status then
      v_type:=case new.status when 'proof_submitted' then 'proof_submitted'
        when 'confirmed' then 'confirmed' when 'rejected' then 'rejected'
        else 'admin_note_updated' end;
    elsif new.admin_note is distinct from old.admin_note then v_type:='admin_note_updated';
    else return new; end if;
    v_from:=old.status; v_to:=new.status;
  end if;
  insert into public.payment_order_events(payment_order_id,actor_id,event_type,from_status,to_status,note,metadata)
  values(new.id,auth.uid(),v_type,v_from,v_to,
    case when tg_op='UPDATE' then new.admin_note else null end,
    jsonb_build_object('reference',new.reference,'amount_ngn',new.amount_ngn,
      'currency',new.currency,'method',new.method,'transfer_reference',new.transfer_reference,'proof_path',new.proof_url));
  return new;
end
$function$;
revoke all on function public.cv_payment_order_audit() from public,anon,authenticated;
drop trigger if exists cv_payment_order_audit on public.payment_orders;
create trigger cv_payment_order_audit after insert or update on public.payment_orders
for each row execute function public.cv_payment_order_audit();
