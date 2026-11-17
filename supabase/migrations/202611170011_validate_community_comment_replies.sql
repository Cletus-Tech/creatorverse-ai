-- Ensure comment replies can only target a comment on the same post.
drop policy if exists "Community comments create own" on public.community_comments;
create policy "Community comments create own"
on public.community_comments for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.community_posts p
    where p.id = community_comments.post_id and p.status = 'published'
  )
  and (
    parent_id is null
    or exists (
      select 1 from public.community_comments parent
      where parent.id = community_comments.parent_id
        and parent.post_id = community_comments.post_id
    )
  )
);
