-- Extend billboard creatives with dynamic countdown slides.
alter table public.billboard_items
  drop constraint if exists billboard_items_media_type_check;
alter table public.billboard_items
  add constraint billboard_items_media_type_check
  check (media_type in ('text','image','video','countdown'));
alter table public.billboard_items
  add column if not exists countdown_target_at timestamptz,
  add column if not exists countdown_timezone text not null default 'Africa/Lagos',
  add column if not exists countdown_complete_label text not null default 'EVENT STARTED';
alter table public.billboard_items
  drop constraint if exists billboard_countdown_target_required;
alter table public.billboard_items
  add constraint billboard_countdown_target_required
  check (media_type <> 'countdown' or countdown_target_at is not null);
