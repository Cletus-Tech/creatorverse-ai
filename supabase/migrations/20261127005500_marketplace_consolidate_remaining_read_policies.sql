drop policy if exists "Marketplace admins read order items" on public.marketplace_order_items;
drop policy if exists "Participants read marketplace order items" on public.marketplace_order_items;
create policy "Marketplace participants and admins read order items"
on public.marketplace_order_items for select to authenticated
using (private.marketplace_user_owns_order_item(order_id,seller_id,(select auth.uid())) or (select public.is_admin()));

drop policy if exists "Buyers and participating sellers read marketplace orders" on public.marketplace_orders;
drop policy if exists "Marketplace admins read orders" on public.marketplace_orders;
create policy "Marketplace participants and admins read orders"
on public.marketplace_orders for select to authenticated
using (private.marketplace_user_is_order_participant(id,(select auth.uid())) or (select public.is_admin()));

drop policy if exists "Marketplace admins read reviews" on public.marketplace_reviews;
drop policy if exists "Users read published marketplace reviews" on public.marketplace_reviews;
create policy "Marketplace users and admins read reviews"
on public.marketplace_reviews for select to authenticated
using (status='published' or buyer_id=(select auth.uid()) or (select public.is_admin()));
