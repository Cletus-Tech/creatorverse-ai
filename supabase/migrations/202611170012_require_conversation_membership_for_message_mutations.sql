-- Require an active conversation membership for message edits and global deletion.
create or replace function private.cv_edit_direct_message(p_message_id uuid, p_body text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $cv$
declare
  v_message public.cv_direct_messages%rowtype;
  v_user uuid := auth.uid();
  v_body text := btrim(coalesce(p_body, ''));
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if char_length(v_body) < 1 or char_length(v_body) > 4000 then
    raise exception 'Message must contain between 1 and 4000 characters';
  end if;
  select * into v_message from public.cv_direct_messages where id = p_message_id for update;
  if not found or v_message.sender_id <> v_user then raise exception 'You can only edit your own messages'; end if;
  if not exists (
    select 1 from public.cv_conversations c
    where c.id = v_message.conversation_id
      and ((not c.is_group and (c.user_a = v_user or c.user_b = v_user))
        or (c.is_group and private.cv_is_conversation_member(c.id)))
  ) then raise exception 'You are no longer a member of this conversation'; end if;
  if v_message.deleted_at is not null then raise exception 'Deleted messages cannot be edited'; end if;
  if v_message.created_at < now() - interval '5 minutes' then raise exception 'Messages can only be edited within five minutes'; end if;
  update public.cv_direct_messages set body = v_body, edited_at = now()
  where id = p_message_id and sender_id = v_user;
end;
$cv$;

create or replace function private.cv_delete_direct_message_everyone(p_message_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $cv$
declare
  v_message public.cv_direct_messages%rowtype;
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select * into v_message from public.cv_direct_messages where id = p_message_id for update;
  if not found or v_message.sender_id <> v_user then raise exception 'You can only delete your own messages for everyone'; end if;
  if not exists (
    select 1 from public.cv_conversations c
    where c.id = v_message.conversation_id
      and ((not c.is_group and (c.user_a = v_user or c.user_b = v_user))
        or (c.is_group and private.cv_is_conversation_member(c.id)))
  ) then raise exception 'You are no longer a member of this conversation'; end if;
  if v_message.deleted_at is not null then return; end if;
  if v_message.created_at < now() - interval '5 minutes' then raise exception 'Delete for everyone is only available within five minutes'; end if;
  update public.cv_direct_messages
  set body = 'This message was deleted', deleted_at = now(), edited_at = null,
      attachment_path = null, attachment_name = null, attachment_mime = null, attachment_size = null
  where id = p_message_id and sender_id = v_user;
end;
$cv$;

revoke all on function private.cv_edit_direct_message(uuid, text) from public, anon;
revoke all on function private.cv_delete_direct_message_everyone(uuid) from public, anon;
grant execute on function private.cv_edit_direct_message(uuid, text) to authenticated;
grant execute on function private.cv_delete_direct_message_everyone(uuid) to authenticated;
