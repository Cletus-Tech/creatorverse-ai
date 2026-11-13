-- CreatorVerse Marketplace foundation (additive; apply through reviewed Supabase migration workflow).
-- This establishes seller onboarding and moderated listings only.
-- Checkout, payments, orders, escrow, reviews and messaging are intentionally out of scope.

create table if not exists public.marketplace_sellers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete restrict,
  display_name text not null check (char_length(trim(display_name)) between 2 and 80),
  seller_type text not null default 'student' check (seller_type in ('student','campus_vendor','service_provider')),
  institution text,
  campus text,
  contact_method text check (contact_method is null or contact_method in ('in_app','phone','email')),
  public_contact text,
  bio text check (bio is null or char_length(bio) <= 500),
  status text not null default 'pending' check (status in ('pending','verified','rejected','suspended')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists marketplace_sellers_status_idx on public.marketplace_sellers(status, created_at desc);
create index if not exists marketplace_sellers_user_idx on public.marketplace_sellers(user_id);

create table if not exists public.marketplace_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text,
  active boolean not null default true,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

insert into public.marketplace_categories(name,slug,description,position) values
 ('Books & Study','books-study','Textbooks, calculators and study materials',10),
 ('Electronics','electronics','Phones, computers and accessories',20),
 ('Fashion','fashion','Clothing, shoes and accessories',30),
 ('Food & Essentials','food-essentials','Food, groceries and everyday essentials',40),
 ('Services','services','Creative, technical and campus services',50),
 ('Rentals','rentals','Items available to borrow or hire',60),
 ('Free & Giveaways','free-giveaways','Items offered at no cost',70)
on conflict (slug) do nothing;

create table if not exists public.marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.marketplace_sellers(id) on delete restrict,
  category_id uuid not null references public.marketplace_categories(id) on delete restrict,
  title text not null check (char_length(trim(title)) between 4 and 100),
  description text not null check (char_length(trim(description)) between 10 and 3000),
  listing_type text not null default 'product' check (listing_type in ('product','service','rental','free')),
  item_condition text check (item_condition is null or item_condition in ('new','like_new','good','fair','not_applicable')),
  price_ngn integer check (price_ngn is null or price_ngn >= 0),
  negotiable boolean not null default false,
  location_label text,
  institution text,
  campus text,
  image_urls text[] not null default '{}',
  status text not null default 'draft' check (status in ('draft','pending_review','published','rejected','archived','sold')),
  moderation_note text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint marketplace_listing_image_limit check (cardinality(image_urls) <= 8)
);
create index if not exists marketplace_listings_public_idx on public.marketplace_listings(status, category_id, created_at desc);
create index if not exists marketplace_listings_seller_idx on public.marketplace_listings(seller_id, created_at desc);
create index if not exists marketplace_listings_campus_idx on public.marketplace_listings(institution, campus, status);

create or replace function public.marketplace_guard_seller()
returns trigger language plpgsql security definer
set search_path = pg_catalog, public, auth
as $$
declare is_admin boolean;
begin
  is_admin := coalesce(public.is_admin(), false);
  if tg_op = 'INSERT' then
    if auth.uid() is null or new.user_id <> auth.uid() then raise exception 'Invalid seller account owner'; end if;
    new.status := 'pending';
    new.reviewed_by := null;
    new.reviewed_at := null;
    new.review_note := null;
  elsif not is_admin then
    if new.user_id is distinct from old.user_id
      or new.status is distinct from old.status
      or new.reviewed_by is distinct from old.reviewed_by
      or new.reviewed_at is distinct from old.reviewed_at
      or new.review_note is distinct from old.review_note then
      raise exception 'Seller verification fields are managed by Marketplace administrators';
    end if;
  else
    if new.status is distinct from old.status and new.status in ('verified','rejected','suspended') then
      new.reviewed_by := auth.uid();
      new.reviewed_at := now();
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

create or replace function public.marketplace_guard_listing()
returns trigger language plpgsql security definer
set search_path = pg_catalog, public, auth
as $$
declare is_admin boolean; seller_owner uuid; seller_status text;
begin
  is_admin := coalesce(public.is_admin(), false);
  if tg_op = 'INSERT' then
    select user_id,status into seller_owner,seller_status from public.marketplace_sellers where id=new.seller_id;
    if auth.uid() is null or seller_owner <> auth.uid() then raise exception 'You can only list items from your own seller profile'; end if;
    if seller_status <> 'verified' then raise exception 'Your seller profile must be verified before submitting listings'; end if;
    new.status := 'draft';
    new.reviewed_by := null;
    new.reviewed_at := null;
    new.moderation_note := null;
    new.published_at := null;
  elsif not is_admin then
    select user_id into seller_owner from public.marketplace_sellers where id=old.seller_id;
    if seller_owner is distinct from auth.uid() then raise exception 'You do not own this listing'; end if;
    if new.seller_id is distinct from old.seller_id
      or new.status is distinct from old.status
      or new.reviewed_by is distinct from old.reviewed_by
      or new.reviewed_at is distinct from old.reviewed_at
      or new.moderation_note is distinct from old.moderation_note
      or new.published_at is distinct from old.published_at then
      raise exception 'Listing moderation fields are managed by Marketplace administrators';
    end if;
    if old.status not in ('draft','rejected') then raise exception 'This listing is locked while under review or published'; end if;
  else
    if new.status = 'published' and old.status is distinct from 'published' then
      new.reviewed_by := auth.uid();
      new.reviewed_at := now();
      new.published_at := now();
    end if;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists marketplace_seller_guard on public.marketplace_sellers;
create trigger marketplace_seller_guard before insert or update on public.marketplace_sellers
for each row execute function public.marketplace_guard_seller();
drop trigger if exists marketplace_listing_guard on public.marketplace_listings;
create trigger marketplace_listing_guard before insert or update on public.marketplace_listings
for each row execute function public.marketplace_guard_listing();

alter table public.marketplace_sellers enable row level security;
alter table public.marketplace_categories enable row level security;
alter table public.marketplace_listings enable row level security;

grant select, insert, update on public.marketplace_sellers to authenticated;
grant select on public.marketplace_categories to anon, authenticated;
grant select, insert, update on public.marketplace_listings to authenticated;
grant select on public.marketplace_listings to anon;

drop policy if exists "Marketplace users read own seller profile" on public.marketplace_sellers;
create policy "Marketplace users read own seller profile" on public.marketplace_sellers
for select to authenticated using (user_id = auth.uid() or public.is_admin() or status = 'verified');
drop policy if exists "Marketplace users create seller profile" on public.marketplace_sellers;
create policy "Marketplace users create seller profile" on public.marketplace_sellers
for insert to authenticated with check (user_id = auth.uid() and status = 'pending');
drop policy if exists "Marketplace users update own seller profile" on public.marketplace_sellers;
create policy "Marketplace users update own seller profile" on public.marketplace_sellers
for update to authenticated using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());
drop policy if exists "Marketplace admins manage sellers" on public.marketplace_sellers;
create policy "Marketplace admins manage sellers" on public.marketplace_sellers
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Marketplace categories are public" on public.marketplace_categories;
create policy "Marketplace categories are public" on public.marketplace_categories
for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "Marketplace admins manage categories" on public.marketplace_categories;
create policy "Marketplace admins manage categories" on public.marketplace_categories
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Marketplace published listings are public" on public.marketplace_listings;
create policy "Marketplace published listings are public" on public.marketplace_listings
for select to anon, authenticated using (status = 'published');
drop policy if exists "Marketplace sellers read own listings" on public.marketplace_listings;
create policy "Marketplace sellers read own listings" on public.marketplace_listings
for select to authenticated using (exists(select 1 from public.marketplace_sellers s where s.id = seller_id and s.user_id = auth.uid()) or public.is_admin());
drop policy if exists "Marketplace verified sellers create drafts" on public.marketplace_listings;
create policy "Marketplace verified sellers create drafts" on public.marketplace_listings
for insert to authenticated with check (
  status = 'draft'
  and exists(select 1 from public.marketplace_sellers s where s.id = seller_id and s.user_id = auth.uid() and s.status = 'verified')
);
drop policy if exists "Marketplace sellers update own drafts" on public.marketplace_listings;
create policy "Marketplace sellers update own drafts" on public.marketplace_listings
for update to authenticated using (
  exists(select 1 from public.marketplace_sellers s where s.id = seller_id and s.user_id = auth.uid())
) with check (
  exists(select 1 from public.marketplace_sellers s where s.id = seller_id and s.user_id = auth.uid())
);
drop policy if exists "Marketplace admins manage listings" on public.marketplace_listings;
create policy "Marketplace admins manage listings" on public.marketplace_listings
for all to authenticated using (public.is_admin()) with check (public.is_admin());
