-- Social media, story video, messaging attachment and public-profile privacy foundations.
-- Applied to the active CreatorVerse Supabase project on 2026-11-16.

alter table public.profiles
  add column if not exists avatar_is_public boolean not null default false;

alter table public.public_profiles drop column if exists role;
alter table public.public_profiles
  add column if not exists avatar_is_public boolean not null default false;

create or replace function public.sync_public_profile()
returns trigger
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
begin
  insert into public.public_profiles (
    id, full_name, avatar_url, username, bio, cover_url, location,
    website_url, skills, status_text, verified_badge, avatar_is_public,
    created_at, updated_at
  )
  values (
    new.id, new.full_name,
    case when new.avatar_is_public then new.avatar_url else null end,
    new.username, new.bio, new.cover_url, new.location,
    new.website_url, new.skills, new.status_text, new.verified_badge,
    new.avatar_is_public, new.created_at, new.updated_at
  )
  on conflict (id) do update set
    full_name=excluded.full_name,
    avatar_url=excluded.avatar_url,
    username=excluded.username,
    bio=excluded.bio,
    cover_url=excluded.cover_url,
    location=excluded.location,
    website_url=excluded.website_url,
    skills=excluded.skills,
    status_text=excluded.status_text,
    verified_badge=excluded.verified_badge,
    avatar_is_public=excluded.avatar_is_public,
    created_at=excluded.created_at,
    updated_at=excluded.updated_at;
  return new;
end;
$function$;

update public.public_profiles pp
set avatar_url=case when p.avatar_is_public then p.avatar_url else null end,
    avatar_is_public=p.avatar_is_public
from public.profiles p where p.id=pp.id;

alter table public.community_posts
  add column if not exists media_type text not null default 'image';
alter table public.community_posts
  drop constraint if exists community_posts_media_type_check;
alter table public.community_posts
  add constraint community_posts_media_type_check
  check (media_type in ('image','video','none'));
update public.community_posts
set media_type=case when image_url is null then 'none' else 'image' end;

alter table public.cv_stories
  drop constraint if exists cv_stories_media_type_check;
alter table public.cv_stories
  drop constraint if exists cv_stories_media_type_valid;
alter table public.cv_stories
  add constraint cv_stories_media_type_check
  check (media_type in ('text','image','video'));
alter table public.cv_stories
  add constraint cv_stories_media_type_valid
  check (
    (media_type='text' and media_url is null) or
    (media_type in ('image','video') and media_url is not null)
  );

update storage.buckets
set file_size_limit=52428800,
    allowed_mime_types=array[
      'image/jpeg','image/png','image/webp','image/gif',
      'video/mp4','video/webm','video/quicktime'
    ]
where id='community-media';

update storage.buckets
set file_size_limit=52428800,
    allowed_mime_types=array[
      'image/jpeg','image/png','image/webp','image/gif',
      'video/mp4','video/webm','video/quicktime',
      'application/pdf','text/plain','application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/zip'
    ]
where id='cv-chat-files';
