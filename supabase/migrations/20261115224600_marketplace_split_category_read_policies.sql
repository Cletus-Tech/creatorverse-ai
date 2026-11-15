-- Keep public category reads independent of authenticated-only admin helpers.
drop policy if exists "Marketplace categories are public" on public.marketplace_categories;
create policy "Marketplace active categories are public"
on public.marketplace_categories for select to anon
using (active);
create policy "Marketplace users read active categories or admins read all"
on public.marketplace_categories for select to authenticated
using (active or public.is_admin());
