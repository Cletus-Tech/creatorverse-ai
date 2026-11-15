-- Tune Marketplace foreign-key lookups and consolidate authenticated RLS policies.
create index if not exists marketplace_enquiry_messages_sender_idx on public.marketplace_enquiry_messages(sender_id);
create index if not exists marketplace_listings_category_idx on public.marketplace_listings(category_id);
create index if not exists marketplace_listings_reviewed_by_idx on public.marketplace_listings(reviewed_by);
create index if not exists marketplace_saved_listings_listing_idx on public.marketplace_saved_listings(listing_id);
create index if not exists marketplace_sellers_reviewed_by_idx on public.marketplace_sellers(reviewed_by);

-- Sellers: one authenticated policy per operation, with public verified cards
-- exposed separately to anonymous visitors.
drop policy if exists "Marketplace users read own seller profile" on public.marketplace_sellers;
drop policy if exists "Marketplace public can view verified seller cards" on public.marketplace_sellers;
drop policy if exists "Marketplace admins manage sellers" on public.marketplace_sellers;
create policy "Marketplace seller cards are public to visitors"
on public.marketplace_sellers for select to anon using (status='verified');
create policy "Marketplace authenticated users read allowed seller profiles"
on public.marketplace_sellers for select to authenticated
using (user_id=(select auth.uid()) or status='verified' or (select public.is_admin()));
drop policy if exists "Marketplace users create seller profile" on public.marketplace_sellers;
create policy "Marketplace users create seller profile"
on public.marketplace_sellers for insert to authenticated
with check (user_id=(select auth.uid()) and status='pending');
drop policy if exists "Marketplace users update own seller profile" on public.marketplace_sellers;
create policy "Marketplace users and admins update seller profiles"
on public.marketplace_sellers for update to authenticated
using (user_id=(select auth.uid()) or (select public.is_admin()))
with check (user_id=(select auth.uid()) or (select public.is_admin()));

-- Categories: active categories are public; authenticated admins may also
-- read inactive categories and update category availability.
drop policy if exists "Marketplace users read active categories or admins read all" on public.marketplace_categories;
create policy "Marketplace users read active categories or admins read all"
on public.marketplace_categories for select to authenticated
using (active or (select public.is_admin()));
drop policy if exists "Marketplace admins manage categories" on public.marketplace_categories;
create policy "Marketplace admins update categories"
on public.marketplace_categories for update to authenticated
using ((select public.is_admin())) with check ((select public.is_admin()));

-- Listings: published discovery, seller ownership, and administrator moderation
-- are consolidated so each authenticated operation has one policy.
drop policy if exists "Marketplace published listings are public" on public.marketplace_listings;
drop policy if exists "Marketplace sellers read own listings" on public.marketplace_listings;
drop policy if exists "Marketplace admins manage listings" on public.marketplace_listings;
create policy "Marketplace published listings are public"
on public.marketplace_listings for select to anon using (status='published');
create policy "Marketplace authenticated users read published or owned listings"
on public.marketplace_listings for select to authenticated
using (
  status='published'
  or exists(select 1 from public.marketplace_sellers s where s.id=seller_id and s.user_id=(select auth.uid()))
  or (select public.is_admin())
);
drop policy if exists "Marketplace verified sellers create drafts" on public.marketplace_listings;
create policy "Marketplace verified sellers create drafts"
on public.marketplace_listings for insert to authenticated
with check (
  status='draft'
  and exists(select 1 from public.marketplace_sellers s where s.id=seller_id and s.user_id=(select auth.uid()) and s.status='verified')
);
drop policy if exists "Marketplace sellers update own drafts" on public.marketplace_listings;
create policy "Marketplace sellers or admins update listings"
on public.marketplace_listings for update to authenticated
using (
  exists(select 1 from public.marketplace_sellers s where s.id=seller_id and s.user_id=(select auth.uid()))
  or (select public.is_admin())
)
with check (
  exists(select 1 from public.marketplace_sellers s where s.id=seller_id and s.user_id=(select auth.uid()))
  or (select public.is_admin())
);
