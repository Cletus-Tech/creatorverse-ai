-- Seven-state reactions for the native CreatorVerse community.
create table if not exists public.community_reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction_type text not null check (reaction_type in ('like','love','care','haha','wow','sad','angry')),
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);
create index if not exists community_reactions_post_created_idx
  on public.community_reactions(post_id, created_at desc);
alter table public.community_reactions enable row level security;
drop policy if exists "Community reactions are visible to everyone" on public.community_reactions;
create policy "Community reactions are visible to everyone"
  on public.community_reactions for select using (true);
drop policy if exists "Members can add their own reactions" on public.community_reactions;
create policy "Members can add their own reactions"
  on public.community_reactions for insert to authenticated
  with check (auth.uid() = user_id);
drop policy if exists "Members can change their own reactions" on public.community_reactions;
create policy "Members can change their own reactions"
  on public.community_reactions for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Members can remove their own reactions" on public.community_reactions;
create policy "Members can remove their own reactions"
  on public.community_reactions for delete to authenticated
  using (auth.uid() = user_id);
-- Preserve existing likes as the Like reaction during rollout.
insert into public.community_reactions (post_id, user_id, reaction_type)
select post_id, user_id, 'like' from public.community_likes
on conflict (post_id, user_id) do nothing;
