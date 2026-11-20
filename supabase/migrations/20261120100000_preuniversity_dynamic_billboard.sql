-- CreatorVerse dynamic Pre-University billboard foundation.
create table if not exists public.billboard_items (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(btrim(title)) between 2 and 140),
  message text not null default '' check (char_length(message) <= 1200),
  media_type text not null default 'text' check (media_type in ('text','image','video')),
  media_url text,
  button_label text,
  button_url text,
  starts_at timestamptz,
  ends_at timestamptz,
  is_published boolean not null default false,
  display_order integer not null default 0,
  duration_seconds integer not null default 10 check (duration_seconds between 3 and 120),
  created_by uuid references auth.users(id) on delete set null,
  click_count bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint billboard_button_pair check (
    (nullif(btrim(button_label),'') is null and nullif(btrim(button_url),'') is null)
    or (nullif(btrim(button_label),'') is not null and nullif(btrim(button_url),'') is not null)
  ),
  constraint billboard_media_url_valid check (
    media_url is null or media_url ~* '^https?://'
  ),
  constraint billboard_button_url_valid check (
    button_url is null or button_url ~* '^(https?://|/|[a-zA-Z0-9_-]+\.html([?#].*)?)'
  )
);
create index if not exists billboard_items_public_schedule_idx
  on public.billboard_items (is_published, display_order, starts_at, ends_at);
alter table public.billboard_items enable row level security;
drop policy if exists "Public can read active billboard items" on public.billboard_items;
create policy "Public can read active billboard items"
  on public.billboard_items for select to anon, authenticated
  using (is_published = true and (starts_at is null or starts_at <= now()) and (ends_at is null or ends_at > now()));
drop policy if exists "Admins manage billboard items" on public.billboard_items;
create policy "Admins manage billboard items"
  on public.billboard_items for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select on public.billboard_items to anon, authenticated;
grant insert, update, delete on public.billboard_items to authenticated;

create or replace function public.record_billboard_click(p_item_id uuid)
returns boolean language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  update public.billboard_items
    set click_count = click_count + 1
    where id = p_item_id and is_published = true
      and (starts_at is null or starts_at <= now())
      and (ends_at is null or ends_at > now());
  return found;
end;
$$;
revoke all on function public.record_billboard_click(uuid) from public;
grant execute on function public.record_billboard_click(uuid) to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('billboard-media','billboard-media',true,104857600,
  array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm'])
on conflict (id) do update set public=true, file_size_limit=104857600,
  allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Public can view billboard media" on storage.objects;
create policy "Public can view billboard media" on storage.objects
  for select to anon, authenticated using (bucket_id='billboard-media');
drop policy if exists "Admins upload billboard media" on storage.objects;
create policy "Admins upload billboard media" on storage.objects
  for insert to authenticated with check (bucket_id='billboard-media' and public.is_admin());
drop policy if exists "Admins update billboard media" on storage.objects;
create policy "Admins update billboard media" on storage.objects
  for update to authenticated using (bucket_id='billboard-media' and public.is_admin())
  with check (bucket_id='billboard-media' and public.is_admin());
drop policy if exists "Admins delete billboard media" on storage.objects;
create policy "Admins delete billboard media" on storage.objects
  for delete to authenticated using (bucket_id='billboard-media' and public.is_admin());
