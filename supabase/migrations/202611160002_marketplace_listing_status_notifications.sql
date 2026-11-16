-- Notify Marketplace sellers when an administrator changes listing visibility/status.
create or replace function private.cv_notify_marketplace_listing_status()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipient uuid;
  v_title text;
  v_body text;
begin
  if new.status is not distinct from old.status then return new; end if;
  if new.status not in ('published', 'rejected', 'sold', 'archived') then return new; end if;

  select s.user_id into v_recipient
  from public.marketplace_sellers s where s.id = new.seller_id;
  if v_recipient is null then return new; end if;

  if new.status = 'published' then
    v_title := 'Your Marketplace listing is live';
    v_body := 'Your listing "' || left(new.title, 100) || '" has been approved and published.';
  elsif new.status = 'rejected' then
    v_title := 'Your Marketplace listing needs changes';
    v_body := 'Your listing "' || left(new.title, 100) || '" was not approved. ' ||
      coalesce(nullif(left(new.moderation_note, 300), ''), 'Open your seller workspace to review it.');
  elsif new.status = 'sold' then
    v_title := 'Your Marketplace listing was marked sold';
    v_body := 'Your listing "' || left(new.title, 100) || '" has been marked as sold.';
  else
    v_title := 'Your Marketplace listing was archived';
    v_body := 'Your listing "' || left(new.title, 100) || '" is no longer publicly visible.';
  end if;

  insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
  values (v_recipient, new.reviewed_by, 'marketplace_listing', v_title, v_body,
    'marketplace-seller.html', 'marketplace_listing', new.id);
  return new;
end;
$$;

revoke all on function private.cv_notify_marketplace_listing_status() from public, anon, authenticated;
drop trigger if exists cv_notify_marketplace_listing_status on public.marketplace_listings;
create trigger cv_notify_marketplace_listing_status
after update of status on public.marketplace_listings
for each row execute function private.cv_notify_marketplace_listing_status();
