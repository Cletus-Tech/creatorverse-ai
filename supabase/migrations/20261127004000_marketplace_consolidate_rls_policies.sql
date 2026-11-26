drop policy if exists "Marketplace sellers update own listings" on public.marketplace_listings;

drop policy if exists "Marketplace admins read order events" on public.marketplace_order_events;
drop policy if exists "Participants read marketplace order events" on public.marketplace_order_events;
create policy "Marketplace participants and admins read order events"
on public.marketplace_order_events for select to authenticated
using (private.marketplace_user_is_order_participant(order_id,(select auth.uid())) or (select public.is_admin()));

drop policy if exists "Buyers read their own return requests" on public.marketplace_return_requests;
drop policy if exists "Marketplace admins read return requests" on public.marketplace_return_requests;
create policy "Marketplace buyers and admins read return requests"
on public.marketplace_return_requests for select to authenticated
using (buyer_id=(select auth.uid()) or (select public.is_admin()));
