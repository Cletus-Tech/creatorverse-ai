-- Buyer discovery foundation: safe public seller cards and private saved listings.
-- Additive only. Does not create orders, payments, reviews or buyer/seller messaging.

-- The public seller view must respect underlying-table RLS. Grant anon only the
-- columns used by the safe view, then let RLS expose verified seller rows only.
grant select (id, display_name, seller_type, institution, campus, bio, status, created_at)
on public.marketplace_sellers to anon;

drop policy if exists "Marketplace public can view verified seller cards" on public.marketplace_sellers;
create policy "Marketplace public can view verified seller cards"
on public.marketplace_sellers for select to anon
using (status = 'verified');

create or replace view public.marketplace_public_sellers
with (security_invoker = true)
as
select id, display_name, seller_type, institution, campus, bio, status, created_at
from public.marketplace_sellers
where status = 'verified';

grant select on public.marketplace_public_sellers to anon, authenticated;

create table if not exists public.marketplace_saved_listings (
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid not null references public.marketplace_listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index if not exists marketplace_saved_listings_user_created_idx
on public.marketplace_saved_listings(user_id, created_at desc);

alter table public.marketplace_saved_listings enable row level security;
grant select, insert, delete on public.marketplace_saved_listings to authenticated;

drop policy if exists "Users read their saved marketplace listings" on public.marketplace_saved_listings;
create policy "Users read their saved marketplace listings"
on public.marketplace_saved_listings for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "Users save their own marketplace listings" on public.marketplace_saved_listings;
create policy "Users save their own marketplace listings"
on public.marketplace_saved_listings for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_id and l.status = 'published'
  )
);

drop policy if exists "Users remove their own saved marketplace listings" on public.marketplace_saved_listings;
create policy "Users remove their own saved marketplace listings"
on public.marketplace_saved_listings for delete to authenticated
using (user_id = (select auth.uid()));
