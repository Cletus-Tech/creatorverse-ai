-- CreatorVerse Market commerce foundation.
-- Adds persistent buyer carts, multi-vendor orders, order history, fulfilment events,
-- reviews and return requests. This migration is additive; it does not configure or
-- charge any payment provider. Payment confirmation remains an administrator action.

alter table public.marketplace_listings
  add column if not exists quantity_available integer not null default 1
    check (quantity_available >= 0),
  add column if not exists sku text,
  add column if not exists shipping_required boolean not null default true;

create table if not exists public.marketplace_carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketplace_cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.marketplace_carts(id) on delete cascade,
  listing_id uuid not null references public.marketplace_listings(id) on delete cascade,
  quantity integer not null default 1 check (quantity between 1 and 99),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cart_id, listing_id)
);
create index if not exists marketplace_cart_items_cart_idx
  on public.marketplace_cart_items(cart_id, created_at desc);

create table if not exists public.marketplace_orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  buyer_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'pending_payment'
    check (status in ('pending_payment','paid','processing','ready_for_dispatch','shipped','delivered','cancelled','refund_requested','refunded')),
  payment_method text not null
    check (payment_method in ('bank_transfer','ussd','cash_on_delivery')),
  payment_status text not null default 'pending'
    check (payment_status in ('pending','proof_submitted','confirmed','failed','refunded')),
  subtotal_ngn integer not null check (subtotal_ngn >= 0),
  delivery_fee_ngn integer not null default 0 check (delivery_fee_ngn >= 0),
  total_ngn integer not null check (total_ngn >= 0),
  currency text not null default 'NGN' check (currency = 'NGN'),
  recipient_name text not null check (char_length(trim(recipient_name)) between 2 and 100),
  recipient_phone text not null check (char_length(trim(recipient_phone)) between 7 and 25),
  delivery_address text not null check (char_length(trim(delivery_address)) between 5 and 500),
  delivery_city text not null,
  delivery_state text not null,
  delivery_country text not null default 'Nigeria',
  buyer_note text check (buyer_note is null or char_length(buyer_note) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  delivered_at timestamptz,
  cancelled_at timestamptz
);
create index if not exists marketplace_orders_buyer_idx
  on public.marketplace_orders(buyer_id, created_at desc);
create index if not exists marketplace_orders_status_idx
  on public.marketplace_orders(status, created_at desc);

create table if not exists public.marketplace_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.marketplace_orders(id) on delete restrict,
  listing_id uuid references public.marketplace_listings(id) on delete set null,
  seller_id uuid not null references public.marketplace_sellers(id) on delete restrict,
  title_snapshot text not null,
  image_snapshot text,
  unit_price_ngn integer not null check (unit_price_ngn >= 0),
  quantity integer not null check (quantity between 1 and 99),
  line_total_ngn integer not null check (line_total_ngn >= 0),
  created_at timestamptz not null default now()
);
create index if not exists marketplace_order_items_order_idx
  on public.marketplace_order_items(order_id);
create index if not exists marketplace_order_items_seller_idx
  on public.marketplace_order_items(seller_id, created_at desc);

create table if not exists public.marketplace_order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.marketplace_orders(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now()
);
create index if not exists marketplace_order_events_order_idx
  on public.marketplace_order_events(order_id, created_at);

create table if not exists public.marketplace_reviews (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null unique references public.marketplace_order_items(id) on delete cascade,
  order_id uuid not null references public.marketplace_orders(id) on delete cascade,
  listing_id uuid references public.marketplace_listings(id) on delete set null,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references public.marketplace_sellers(id) on delete restrict,
  rating integer not null check (rating between 1 and 5),
  body text check (body is null or char_length(body) <= 1200),
  status text not null default 'pending' check (status in ('pending','published','hidden')),
  created_at timestamptz not null default now()
);
create index if not exists marketplace_reviews_listing_idx
  on public.marketplace_reviews(listing_id, status, created_at desc);

create table if not exists public.marketplace_return_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.marketplace_orders(id) on delete restrict,
  order_item_id uuid not null references public.marketplace_order_items(id) on delete restrict,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (char_length(trim(reason)) between 5 and 1000),
  status text not null default 'requested'
    check (status in ('requested','under_review','approved','rejected','received','refunded')),
  resolution_note text check (resolution_note is null or char_length(resolution_note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists marketplace_returns_buyer_idx
  on public.marketplace_return_requests(buyer_id, created_at desc);

alter table public.marketplace_carts enable row level security;
alter table public.marketplace_cart_items enable row level security;
alter table public.marketplace_orders enable row level security;
alter table public.marketplace_order_items enable row level security;
alter table public.marketplace_order_events enable row level security;
alter table public.marketplace_reviews enable row level security;
alter table public.marketplace_return_requests enable row level security;

grant select, insert, update, delete on public.marketplace_carts to authenticated;
grant select, insert, update, delete on public.marketplace_cart_items to authenticated;
grant select on public.marketplace_orders, public.marketplace_order_items,
  public.marketplace_order_events, public.marketplace_reviews,
  public.marketplace_return_requests to authenticated;

drop policy if exists "Buyers manage their own marketplace cart" on public.marketplace_carts;
create policy "Buyers manage their own marketplace cart"
on public.marketplace_carts for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "Buyers manage items in their own marketplace cart" on public.marketplace_cart_items;
create policy "Buyers manage items in their own marketplace cart"
on public.marketplace_cart_items for all to authenticated
using (exists (select 1 from public.marketplace_carts c
  where c.id = cart_id and c.user_id = (select auth.uid())))
with check (exists (select 1 from public.marketplace_carts c
  where c.id = cart_id and c.user_id = (select auth.uid())));

-- SECURITY DEFINER helpers avoid recursive RLS between orders, items and events.
create or replace function private.marketplace_user_is_order_participant(p_order_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.marketplace_orders o
    where o.id = p_order_id and o.buyer_id = p_user_id
  ) or exists (
    select 1
    from public.marketplace_order_items oi
    join public.marketplace_sellers s on s.id = oi.seller_id
    where oi.order_id = p_order_id and s.user_id = p_user_id
  );
$$;

create or replace function private.marketplace_user_owns_order_item(p_order_id uuid, p_seller_id uuid, p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.marketplace_orders o
    where o.id = p_order_id and o.buyer_id = p_user_id
  ) or exists (
    select 1 from public.marketplace_sellers s
    where s.id = p_seller_id and s.user_id = p_user_id
  );
$$;

revoke all on function private.marketplace_user_is_order_participant(uuid,uuid) from public, anon, authenticated;
revoke all on function private.marketplace_user_owns_order_item(uuid,uuid,uuid) from public, anon, authenticated;

drop policy if exists "Buyers and participating sellers read marketplace orders" on public.marketplace_orders;
create policy "Buyers and participating sellers read marketplace orders"
on public.marketplace_orders for select to authenticated
using (private.marketplace_user_is_order_participant(id, (select auth.uid())));

drop policy if exists "Participants read marketplace order items" on public.marketplace_order_items;
create policy "Participants read marketplace order items"
on public.marketplace_order_items for select to authenticated
using (private.marketplace_user_owns_order_item(order_id, seller_id, (select auth.uid())));

drop policy if exists "Participants read marketplace order events" on public.marketplace_order_events;
create policy "Participants read marketplace order events"
on public.marketplace_order_events for select to authenticated
using (private.marketplace_user_is_order_participant(order_id, (select auth.uid())));

drop policy if exists "Users read published marketplace reviews" on public.marketplace_reviews;
create policy "Users read published marketplace reviews"
on public.marketplace_reviews for select to authenticated
using (status = 'published' or buyer_id = (select auth.uid()));

drop policy if exists "Buyers read their own return requests" on public.marketplace_return_requests;
create policy "Buyers read their own return requests"
on public.marketplace_return_requests for select to authenticated
using (buyer_id = (select auth.uid()));

-- All cart/order mutations go through security-definer RPCs. Clients cannot set
-- order totals, payment status, fulfilment status, review moderation or refunds.
revoke insert, update, delete on public.marketplace_orders from authenticated;
revoke insert, update, delete on public.marketplace_order_items from authenticated;
revoke insert, update, delete on public.marketplace_order_events from authenticated;
revoke insert, update, delete on public.marketplace_reviews from authenticated;
revoke insert, update, delete on public.marketplace_return_requests from authenticated;

create or replace function public.marketplace_add_to_cart(p_listing_id uuid, p_quantity integer default 1)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_cart uuid;
  v_listing public.marketplace_listings%rowtype;
  v_seller_status text;
  v_in_cart integer := 0;
begin
  if v_user is null then raise exception 'Sign in to add items to your cart'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 99 then raise exception 'Choose a quantity from 1 to 99'; end if;
  select l.* into v_listing
  from public.marketplace_listings l
  where l.id = p_listing_id and l.status = 'published';
  if v_listing.id is null then raise exception 'This listing is no longer available'; end if;
  select s.status into v_seller_status from public.marketplace_sellers s where s.id = v_listing.seller_id;
  if v_seller_status <> 'verified' then raise exception 'This seller is not currently verified'; end if;
  if v_listing.listing_type = 'service' then raise exception 'Services must be booked through seller enquiries in this release'; end if;
  if v_listing.listing_type = 'free' then p_quantity := 1; end if;
  select c.id into v_cart from public.marketplace_carts c where c.user_id = v_user;
  if v_cart is not null then
    select coalesce(i.quantity, 0) into v_in_cart
    from public.marketplace_cart_items i where i.cart_id = v_cart and i.listing_id = p_listing_id;
  end if;
  if v_in_cart + p_quantity > v_listing.quantity_available then
    raise exception 'Only % item(s) are currently available', greatest(v_listing.quantity_available - v_in_cart, 0);
  end if;
  insert into public.marketplace_carts(user_id) values (v_user)
  on conflict (user_id) do update set updated_at = now()
  returning id into v_cart;
  insert into public.marketplace_cart_items(cart_id, listing_id, quantity)
  values (v_cart, p_listing_id, p_quantity)
  on conflict (cart_id, listing_id) do update
  set quantity = public.marketplace_cart_items.quantity + excluded.quantity,
      updated_at = now();
  return v_cart;
end;
$$;

create or replace function public.marketplace_update_cart_quantity(p_listing_id uuid, p_quantity integer)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_cart uuid;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  if p_quantity < 1 or p_quantity > 99 then raise exception 'Quantity must be between 1 and 99'; end if;
  select id into v_cart from public.marketplace_carts where user_id = v_user;
  update public.marketplace_cart_items set quantity = p_quantity, updated_at = now()
  where cart_id = v_cart and listing_id = p_listing_id;
  if not found then raise exception 'Cart item not found'; end if;
end;
$$;

create or replace function public.marketplace_remove_from_cart(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_cart uuid;
begin
  if v_user is null then raise exception 'Sign in first'; end if;
  select id into v_cart from public.marketplace_carts where user_id = v_user;
  delete from public.marketplace_cart_items where cart_id = v_cart and listing_id = p_listing_id;
end;
$$;

revoke all on function public.marketplace_add_to_cart(uuid,integer) from public, anon;
revoke all on function public.marketplace_update_cart_quantity(uuid,integer) from public, anon;
revoke all on function public.marketplace_remove_from_cart(uuid) from public, anon;
grant execute on function public.marketplace_add_to_cart(uuid,integer) to authenticated;
grant execute on function public.marketplace_update_cart_quantity(uuid,integer) to authenticated;
grant execute on function public.marketplace_remove_from_cart(uuid) to authenticated;

-- Checkout and payment-provider confirmation are intentionally separate next steps.
-- This avoids accepting unverified client-supplied totals or pretending a payment
-- has succeeded before a configured provider or administrator confirms it.
