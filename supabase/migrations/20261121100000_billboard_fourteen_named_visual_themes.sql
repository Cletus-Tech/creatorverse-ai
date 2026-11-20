-- Persist the named billboard theme independently from its editable colour values.
alter table public.billboard_items
  add column if not exists theme_key text not null default 'gold';

alter table public.billboard_items
  drop constraint if exists billboard_items_theme_key_check,
  add constraint billboard_items_theme_key_check
  check (theme_key in (
    'gold','ocean_blue','forest_green','violet','teal','sunset','emerald',
    'midnight','neon_night','aurora','royal_purple','coral','rose_glow','gold_luxe'
  ));
