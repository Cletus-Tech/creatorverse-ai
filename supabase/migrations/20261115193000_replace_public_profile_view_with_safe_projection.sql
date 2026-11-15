-- Replace the privileged projection view with a separately stored public profile projection.
-- This keeps private fields on profiles inaccessible to anonymous visitors without a SECURITY DEFINER view.
drop view if exists public.public_profiles;

create table public.public_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  full_name text,
  avatar_url text,
  username text,
  bio text not null default '',
  cover_url text,
  location text,
  website_url text,
  skills text[] not null default '{}',
  status_text text not null default '',
  verified_badge text not null default 'none',
  role text not null default 'student',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.public_profiles (
  id, full_name, avatar_url, username, bio, cover_url, location,
  website_url, skills, status_text, verified_badge, role, created_at, updated_at
)
select id, full_name, avatar_url, username, bio, cover_url, location,
       website_url, skills, status_text, verified_badge, role, created_at, updated_at
from public.profiles
on conflict (id) do update set
  full_name=excluded.full_name, avatar_url=excluded.avatar_url, username=excluded.username,
  bio=excluded.bio, cover_url=excluded.cover_url, location=excluded.location,
  website_url=excluded.website_url, skills=excluded.skills, status_text=excluded.status_text,
  verified_badge=excluded.verified_badge, role=excluded.role,
  created_at=excluded.created_at, updated_at=excluded.updated_at;

create or replace function public.sync_public_profile()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
begin
  insert into public.public_profiles (
    id, full_name, avatar_url, username, bio, cover_url, location,
    website_url, skills, status_text, verified_badge, role, created_at, updated_at
  )
  values (
    new.id, new.full_name, new.avatar_url, new.username, new.bio, new.cover_url, new.location,
    new.website_url, new.skills, new.status_text, new.verified_badge, new.role, new.created_at, new.updated_at
  )
  on conflict (id) do update set
    full_name=excluded.full_name, avatar_url=excluded.avatar_url, username=excluded.username,
    bio=excluded.bio, cover_url=excluded.cover_url, location=excluded.location,
    website_url=excluded.website_url, skills=excluded.skills, status_text=excluded.status_text,
    verified_badge=excluded.verified_badge, role=excluded.role,
    created_at=excluded.created_at, updated_at=excluded.updated_at;
  return new;
end;
$function$;

drop trigger if exists sync_public_profile_after_profile_change on public.profiles;
create trigger sync_public_profile_after_profile_change
after insert or update on public.profiles
for each row execute function public.sync_public_profile();

alter table public.public_profiles enable row level security;
revoke all on public.public_profiles from public, anon, authenticated;
grant select on public.public_profiles to anon, authenticated;
create policy "Public profiles are readable"
on public.public_profiles for select to anon, authenticated
using (true);

revoke execute on function public.sync_public_profile() from public, anon, authenticated;
