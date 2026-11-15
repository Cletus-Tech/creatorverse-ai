-- Secure seller submission workflow: owners may submit editable drafts for review,
-- but cannot publish, approve, archive or mark listings sold themselves.
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
      raise exception 'You can only list items from your own seller profile';
    end if;
    if v_seller_status <> 'verified' then
      raise exception 'Your seller profile must be verified before submitting listings';
    end if;
    new.status := 'draft';
    new.reviewed_by := null;
    new.reviewed_at := null;
    new.moderation_note := null;
    new.published_at := null;
  elsif not v_is_admin then
    select user_id into v_seller_owner
    from public.marketplace_sellers where id = old.seller_id;
    if v_seller_owner is distinct from auth.uid() then
      raise exception 'You do not own this listing';
    end if;
    if new.seller_id is distinct from old.seller_id
      or new.reviewed_by is distinct from old.reviewed_by
      or new.reviewed_at is distinct from old.reviewed_at
      or new.moderation_note is distinct from old.moderation_note
      or new.published_at is distinct from old.published_at then
      raise exception 'Listing moderation fields are managed by Marketplace administrators';
    end if;
    if old.status not in ('draft','rejected')
      or new.status not in (old.status,'pending_review') then
      raise exception 'Only a draft or rejected listing can be submitted for review';
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

create or replace function public.marketplace_submit_listing(p_listing_id uuid)
returns public.marketplace_listings
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  v_listing public.marketplace_listings;
  v_owner uuid;
  v_seller_status text;
begin
  if auth.uid() is null then raise exception 'Please sign in first'; end if;
  select s.user_id, s.status into v_owner, v_seller_status
  from public.marketplace_listings l
  join public.marketplace_sellers s on s.id = l.seller_id
  where l.id = p_listing_id;
  if v_owner is distinct from auth.uid() then raise exception 'Listing not found or not yours'; end if;
  if v_seller_status <> 'verified' then raise exception 'Your seller profile must be verified'; end if;
  update public.marketplace_listings
  set status = 'pending_review'
  where id = p_listing_id and status in ('draft','rejected')
  returning * into v_listing;
  if v_listing.id is null then raise exception 'Only draft or rejected listings can be submitted'; end if;
  return v_listing;
end;
$$;

revoke all on function public.marketplace_submit_listing(uuid) from public, anon;
grant execute on function public.marketplace_submit_listing(uuid) to authenticated;
