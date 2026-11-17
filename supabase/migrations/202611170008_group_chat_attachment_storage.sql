-- Extend the existing private chat-file bucket policies to group conversations.
-- The folder layout remains conversation_id/user_id/filename for direct and group chats.

drop policy if exists "CV chat participants read attachments" on storage.objects;
create policy "CV chat participants read attachments"
on storage.objects for select to authenticated
using (
  bucket_id = 'cv-chat-files'
  and exists (
    select 1
    from public.cv_conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or
        (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "CV chat participants upload attachments" on storage.objects;
create policy "CV chat participants upload attachments"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'cv-chat-files'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and exists (
    select 1
    from public.cv_conversations c
    where c.id::text = (storage.foldername(name))[1]
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or
        (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);
