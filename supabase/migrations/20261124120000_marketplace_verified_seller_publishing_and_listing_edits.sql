-- Verified CreatorVerse sellers can publish immediately and manage their listings.
-- Product title remains the one required public identifier. Description, price,
-- photos, condition and location are optional and can be added or changed later.

alter table public.marketplace_listings
  alter column description drop not null,
  drop constraint if exists marketplace_listings_title_check,
  add constraint marketplace_listings_title_check check (char_length(trim(title)) between 1 and 100);

create or replace function public.marketplace_guard_listing()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  v_is_admin boolean;
  v_seller_owner uuid;
  v_seller_status text;
begin
  v_is_admin := coalesce(public.is_admin(), false);

  if tg_op = 'INSERT' then
    select user_id, status into v_seller_owner, v_seller_status
    from public.marketplace_sellers where id = new.seller_id;

    if auth.uid() is null or v_seller_owner is distinct from auth.uid() then
      raise exception 'You can only create listings for your own seller profile';
    end if;
    if v_seller_status <> 'verified' then
      raise exception 'Your seller profile must be verified before publishing listings';
    end if;
    if new.title is null or char_length(trim(new.title)) = 0 then
      raise exception 'Add a product title before publishing';
    end if;
    if not exists(select 1 from public.marketplace_categories c where c.id = new.category_id and c.active) then
      raise exception 'Choose an active marketplace category';
    end if;

    -- No per-listing admin approval for a verified seller.
    new.status := 'published';
    new.reviewed_by := null;
    new.reviewed_at := null;
    new.moderation_note := null;
    new.published_at := now();

  elsif not v_is_admin then
    select user_id, status into v_seller_owner, v_seller_status
    from public.marketplace_sellers where id = old.seller_id;

    if v_seller_owner is distinct from auth.uid() then
      raise exception 'You do not own this listing';
    end if;
    if v_seller_status <> 'verified' then
      raise exception 'Your seller account is not currently active';
    end if;
    if new.seller_id is distinct from old.seller_id
      or new.status is distinct from old.status
      or new.reviewed_by is distinct from old.reviewed_by
      or new.reviewed_at is distinct from old.reviewed_at
      or new.moderation_note is distinct from old.moderation_note
      or new.published_at is distinct from old.published_at then
      raise exception 'Listing ownership and moderation fields cannot be changed by sellers';
    end if;
    if new.title is null or char_length(trim(new.title)) = 0 then
      raise exception 'Add a product title before saving';
    end if;
    if not exists(select 1 from public.marketplace_categories c where c.id = new.category_id and c.active) then
      raise exception 'Choose an active marketplace category';
    end if;
    -- Published listings stay published while the owner edits product details.
    -- Existing drafts/rejected listings become live once saved by a verified seller.
    if old.status in ('draft','rejected','pending_review') then
      new.status := 'published';
      new.published_at := coalesce(old.published_at, now());
    end if;
  else
    if new.status = 'published' and old.status is distinct from 'published' then
      new.reviewed_by := auth.uid();
      new.reviewed_at := now();
      new.published_at := now();
    end if;
  end if;

  new.updated_at := now();
  return new;
end;
$$;

-- Sellers can insert their own listings; the trigger above decides the safe status.
drop policy if exists "Marketplace verified sellers create drafts" on public.marketplace_listings;
create policy "Marketplace verified sellers create listings"
on public.marketplace_listings
for insert to authenticated
with check (
  exists (
    select 1 from public.marketplace_sellers s
    where s.id = seller_id and s.user_id = (select auth.uid()) and s.status = 'verified'
  )
);

drop policy if exists "Marketplace sellers update own drafts" on public.marketplace_listings;
create policy "Marketplace sellers update own listings"
on public.marketplace_listings
for update to authenticated
using (
  exists (
    select 1 from public.marketplace_sellers s
    where s.id = seller_id and s.user_id = (select auth.uid()) and s.status = 'verified'
  )
)
with check (
  exists (
    select 1 from public.marketplace_sellers s
    where s.id = seller_id and s.user_id = (select auth.uid()) and s.status = 'verified'
  )
);

-- Column grants are explicit in this project; include the new editable fields.
revoke select, insert, update on public.marketplace_listings from anon, authenticated;
grant select (id,seller_id,category_id,title,description,listing_type,item_condition,price_ngn,negotiable,location_label,institution,campus,image_urls,status,created_at,published_at,quantity_available,sku,shipping_required)
on public.marketplace_listings to anon, authenticated;
grant insert (seller_id,category_id,title,description,listing_type,item_condition,price_ngn,negotiable,location_label,institution,campus,image_urls,status,quantity_available,sku,shipping_required)
on public.marketplace_listings to authenticated;
grant update (seller_id,category_id,title,description,listing_type,item_condition,price_ngn,negotiable,location_label,institution,campus,image_urls,status,moderation_note,reviewed_by,reviewed_at,published_at,quantity_available,sku,shipping_required)
on public.marketplace_listings to authenticated;

-- Replacing an existing product cover requires UPDATE permission on its own folder.
drop policy if exists "Sellers update images in their own folder" on storage.objects;
create policy "Sellers update images in their own folder"
on storage.objects for update
to authenticated
using (
  bucket_id = 'marketplace-listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'marketplace-listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
