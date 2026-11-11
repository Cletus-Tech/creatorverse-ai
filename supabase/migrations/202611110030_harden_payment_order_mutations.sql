-- Harden payment order mutation boundaries and remove a duplicate permissive UPDATE policy.
-- The client currently submits a transfer reference; receipt URL upload is not implemented.
CREATE OR REPLACE FUNCTION public.cv_payment_order_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'public', 'auth'
AS $function$
declare
  cfg public.payment_settings%rowtype;
  actual_price integer;
  admin_user boolean;
begin
  select * into cfg from public.payment_settings where id=true;
  admin_user := exists(
    select 1 from public.profiles p
    where p.id=auth.uid() and p.role in ('admin','super_admin')
  );
  if tg_op='INSERT' then
    if auth.uid() is null or new.user_id <> auth.uid() then raise exception 'Invalid payment owner'; end if;
    select price_ngn into actual_price from public.courses where id=new.course_id and published=true;
    if actual_price is null or actual_price <= 0 then raise exception 'This course is not available for paid checkout'; end if;
    if new.method='bank_transfer' and (not cfg.bank_transfer_enabled or coalesce(cfg.bank_name,'')='' or coalesce(cfg.account_name,'')='' or coalesce(cfg.account_number,'')='') then raise exception 'Bank transfer is not configured yet'; end if;
    if new.method='ussd' and (not cfg.ussd_enabled or coalesce(cfg.ussd_instructions,'')='') then raise exception 'USSD payment is not configured yet'; end if;
    if new.method='international' then raise exception 'International payments are not available yet'; end if;
    new.amount_ngn := actual_price;
    new.currency := 'NGN';
    new.status := 'pending';
    new.reference := 'CV-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12));
    new.expires_at := now() + make_interval(mins => cfg.payment_window_minutes);
    new.proof_url := null;
    new.transfer_reference := null;
    new.admin_note := null;
    new.confirmed_at := null;
    new.updated_at := now();
  elsif tg_op='UPDATE' then
    if not admin_user then
      if new.user_id is distinct from old.user_id
        or new.course_id is distinct from old.course_id
        or new.amount_ngn is distinct from old.amount_ngn
        or new.currency is distinct from old.currency
        or new.method is distinct from old.method
        or new.reference is distinct from old.reference
        or new.expires_at is distinct from old.expires_at
        or new.proof_url is distinct from old.proof_url
        or new.admin_note is distinct from old.admin_note
        or new.confirmed_at is distinct from old.confirmed_at
        or new.created_at is distinct from old.created_at then
        raise exception 'Payment details and receipt URL are protected';
      end if;
      if old.status not in ('pending','proof_submitted') or new.status not in ('pending','proof_submitted') then raise exception 'This payment can no longer be changed'; end if;
      if old.expires_at <= now() then raise exception 'Payment window has expired'; end if;
      if new.status='proof_submitted' and coalesce(trim(new.transfer_reference),'')='' then raise exception 'Enter your transfer reference before submitting'; end if;
    else
      if new.status='confirmed' and old.status not in ('pending','proof_submitted','confirmed') then raise exception 'Only an active payment request can be confirmed'; end if;
      if new.status='confirmed' and old.status is distinct from 'confirmed' then new.confirmed_at:=now(); end if;
      new.updated_at:=now();
    end if;
  end if;
  return new;
end
$function$;
DROP POLICY IF EXISTS "users update own pending payment orders" ON public.payment_orders;
