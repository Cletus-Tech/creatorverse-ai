-- Allow Facebook-style text-only community updates while retaining existing media posts.
alter table public.community_posts
  alter column image_url drop not null;
