-- Separate permanent dashboard billboard placements from temporary floating overlays.
alter table public.billboard_items
  add column if not exists dashboard_enabled boolean not null default true,
  add column if not exists dashboard_pages text[] not null
    default array['explore','campus','learning','academic']::text[],
  add column if not exists overlay_position text not null default 'bottom_center',
  add column if not exists overlay_size text not null default 'medium';

alter table public.billboard_items
  drop constraint if exists billboard_items_overlay_position_check;
alter table public.billboard_items
  add constraint billboard_items_overlay_position_check
  check (overlay_position in ('top_left','top_center','top_right','bottom_left','bottom_center','bottom_right'));

alter table public.billboard_items
  drop constraint if exists billboard_items_overlay_size_check;
alter table public.billboard_items
  add constraint billboard_items_overlay_size_check
  check (overlay_size in ('small','medium','large'));

create index if not exists billboard_items_dashboard_active_idx
  on public.billboard_items (is_published, dashboard_enabled, display_order);
create index if not exists billboard_items_overlay_active_idx
  on public.billboard_items (is_published, overlay_enabled, starts_at, ends_at);
