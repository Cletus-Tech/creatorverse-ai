-- Marketplace payout RLS policy consolidation and FK indexes.
drop policy if exists "Marketplace admins read seller payout accounts" on public.marketplace_seller_payout_accounts;
drop policy if exists "Sellers manage their own payout account" on public.marketplace_seller_payout_accounts;
create policy "Marketplace admins and owners read seller payout accounts"
on public.marketplace_seller_payout_accounts
for select to authenticated
using (coalesce(public.is_admin(),false) or user_id=(select auth.uid()));

drop policy if exists "Marketplace admins manage seller payouts" on public.marketplace_seller_payouts;
drop policy if exists "Sellers read own payout history" on public.marketplace_seller_payouts;
create policy "Marketplace admins and owners read seller payout history"
on public.marketplace_seller_payouts
for select to authenticated
using (
  coalesce(public.is_admin(),false)
  or exists (
    select 1 from public.marketplace_sellers s
    where s.id=marketplace_seller_payouts.seller_id
      and s.user_id=(select auth.uid())
  )
);

create index if not exists marketplace_seller_payout_accounts_user_idx
  on public.marketplace_seller_payout_accounts(user_id);
create index if not exists marketplace_seller_payout_accounts_verified_by_idx
  on public.marketplace_seller_payout_accounts(verified_by);
create index if not exists marketplace_seller_payouts_order_idx
  on public.marketplace_seller_payouts(order_id);
create index if not exists marketplace_seller_payouts_created_by_idx
  on public.marketplace_seller_payouts(created_by);