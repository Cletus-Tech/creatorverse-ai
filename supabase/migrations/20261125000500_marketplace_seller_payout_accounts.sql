create table if not exists public.marketplace_seller_payout_accounts (
 id uuid primary key default gen_random_uuid(),
 seller_id uuid not null unique references public.marketplace_sellers(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 bank_name text not null,
 bank_code text,
 account_name text not null,
 account_number text not null,
 verified_at timestamptz,
 verified_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint marketplace_seller_payout_account_number_check check (account_number ~ '^[0-9]{10}$')
);
alter table public.marketplace_seller_payout_accounts enable row level security;
drop policy if exists "Sellers manage their own payout account" on public.marketplace_seller_payout_accounts;
create policy "Sellers manage their own payout account" on public.marketplace_seller_payout_accounts
for all to authenticated using (user_id=(select auth.uid())) with check (
 user_id=(select auth.uid()) and exists(
  select 1 from public.marketplace_sellers s where s.id=seller_id and s.user_id=(select auth.uid())
 )
);
drop policy if exists "Marketplace admins read seller payout accounts" on public.marketplace_seller_payout_accounts;
create policy "Marketplace admins read seller payout accounts" on public.marketplace_seller_payout_accounts
for select to authenticated using ((select public.is_admin()));
grant select,insert,update on public.marketplace_seller_payout_accounts to authenticated;
create or replace function public.marketplace_submit_seller_application(
 p_display_name text,p_institution text,p_campus text,p_bio text,
 p_bank_name text,p_account_name text,p_account_number text
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_user uuid:=auth.uid(); v_seller uuid;
begin
 if v_user is null then raise exception 'Sign in to apply as a seller'; end if;
 if char_length(trim(coalesce(p_display_name,''))) not between 2 and 100 then raise exception 'Enter your seller or business name'; end if;
 if char_length(trim(coalesce(p_bank_name,'')))<2 then raise exception 'Choose your bank'; end if;
 if char_length(trim(coalesce(p_account_name,'')))<2 then raise exception 'Enter the bank account name'; end if;
 if trim(coalesce(p_account_number,'')) !~ '^[0-9]{10}$' then raise exception 'Enter a valid 10-digit Nigerian bank account number'; end if;
 if exists(select 1 from public.marketplace_sellers where user_id=v_user) then raise exception 'A seller application already exists for this account'; end if;
 insert into public.marketplace_sellers(user_id,display_name,seller_type,institution,campus,bio)
 values(v_user,trim(p_display_name),'student',nullif(trim(coalesce(p_institution,'')),''),nullif(trim(coalesce(p_campus,'')),''),nullif(trim(coalesce(p_bio,'')),''))
 returning id into v_seller;
 insert into public.marketplace_seller_payout_accounts(seller_id,user_id,bank_name,account_name,account_number)
 values(v_seller,v_user,trim(p_bank_name),trim(p_account_name),trim(p_account_number));
 return v_seller;
end;
$$;
revoke execute on function public.marketplace_submit_seller_application(text,text,text,text,text,text,text) from public,anon;
grant execute on function public.marketplace_submit_seller_application(text,text,text,text,text,text,text) to authenticated;
