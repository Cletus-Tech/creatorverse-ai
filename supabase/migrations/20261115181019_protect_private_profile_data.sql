-- Keep email and other account data private while preserving public creator profiles.
drop policy if exists "profiles public read" on public.profiles;

revoke select on table public.profiles from public, anon, authenticated;
grant select on table public.profiles to authenticated;

create or replace view public.public_profiles
with (security_barrier = true, security_invoker = false)
as
select id, full_name, avatar_url, username, bio, cover_url, location,
       website_url, skills, status_text, verified_badge, role, created_at, updated_at
from public.profiles;

revoke all on public.public_profiles from public;
grant select on public.public_profiles to anon, authenticated;
