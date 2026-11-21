-- Independent pinned countdown and temporary cross-page billboard overlays.
alter table public.billboard_items
  add column if not exists is_countdown_pinned boolean not null default false,
  add column if not exists overlay_enabled boolean not null default false,
  add column if not exists overlay_pages text[] not null default array['all']::text[],
  add column if not exists overlay_duration_seconds integer not null default 8;

alter table public.billboard_items
  drop constraint if exists billboard_overlay_duration_check,
  add constraint billboard_overlay_duration_check
    check (overlay_duration_seconds between 3 and 120);

create unique index if not exists billboard_one_pinned_countdown
  on public.billboard_items ((is_countdown_pinned))
  where is_countdown_pinned = true;

create index if not exists billboard_overlay_active_idx
  on public.billboard_items (overlay_enabled, is_published, display_order);

comment on column public.billboard_items.is_countdown_pinned is
  'When true, this countdown is shown independently of the rotating billboard slides.';
comment on column public.billboard_items.overlay_enabled is
  'When true, this published billboard item may appear as a temporary overlay on selected application pages.';
comment on column public.billboard_items.overlay_pages is
  'Page keys: all, landing, community, profiles, dashboards, campus, learning, messages, marketplace, academic.';
comment on column public.billboard_items.overlay_duration_seconds is
  'Number of seconds the temporary overlay remains visible on a matching page.';
