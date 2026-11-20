alter table public.billboard_items
  add column if not exists text_color text not null default '#F4F7FB',
  add column if not exists background_end_color text not null default '#102329',
  add column if not exists title_animation text not null default 'typewriter',
  add column if not exists transition_effect text not null default 'slide',
  add column if not exists media_fit text not null default 'cover',
  add column if not exists overlay_opacity numeric(3,2) not null default 0.58,
  add column if not exists kicker_text text not null default 'CREATORVERSE • LIVE UPDATES';

alter table public.billboard_items
  drop constraint if exists billboard_items_title_animation_check,
  add constraint billboard_items_title_animation_check
    check (title_animation in ('none','typewriter','fade','rise')),
  drop constraint if exists billboard_items_transition_effect_check,
  add constraint billboard_items_transition_effect_check
    check (transition_effect in ('fade','slide','zoom')),
  drop constraint if exists billboard_items_media_fit_check,
  add constraint billboard_items_media_fit_check
    check (media_fit in ('cover','contain')),
  drop constraint if exists billboard_items_overlay_opacity_check,
  add constraint billboard_items_overlay_opacity_check
    check (overlay_opacity >= 0 and overlay_opacity <= 0.95);

update storage.buckets
set allowed_mime_types = array[
  'image/jpeg','image/png','image/webp','image/gif',
  'video/mp4','video/webm','video/quicktime'
]
where id = 'billboard-media';
