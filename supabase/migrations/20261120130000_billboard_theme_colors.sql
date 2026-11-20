-- Add safe, admin-configurable billboard theme colors.
alter table public.billboard_items
  add column if not exists background_color text not null default '#071426',
  add column if not exists accent_color text not null default '#12a984',
  add column if not exists button_color text not null default '#247be9';
alter table public.billboard_items
  drop constraint if exists billboard_theme_colors_valid;
alter table public.billboard_items
  add constraint billboard_theme_colors_valid
  check (
    background_color ~ '^#[0-9A-Fa-f]{6}$'
    and accent_color ~ '^#[0-9A-Fa-f]{6}$'
    and button_color ~ '^#[0-9A-Fa-f]{6}$'
  );
