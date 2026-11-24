-- Allow marketplace administrators to inspect orders and their audit trail.
drop policy if exists "Marketplace admins read orders" on public.marketplace_orders;
create policy "Marketplace admins read orders" on public.marketplace_orders
for select to authenticated using ((select public.is_admin()));
drop policy if exists "Marketplace admins read order items" on public.marketplace_order_items;
create policy "Marketplace admins read order items" on public.marketplace_order_items
for select to authenticated using ((select public.is_admin()));
drop policy if exists "Marketplace admins read order events" on public.marketplace_order_events;
create policy "Marketplace admins read order events" on public.marketplace_order_events
for select to authenticated using ((select public.is_admin()));
drop policy if exists "Marketplace admins read return requests" on public.marketplace_return_requests;
create policy "Marketplace admins read return requests" on public.marketplace_return_requests
for select to authenticated using ((select public.is_admin()));
drop policy if exists "Marketplace admins read reviews" on public.marketplace_reviews;
create policy "Marketplace admins read reviews" on public.marketplace_reviews
for select to authenticated using ((select public.is_admin()));
