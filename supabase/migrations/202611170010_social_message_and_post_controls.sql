-- CreatorVerse message controls and social post interactions.
-- Message editing and delete-for-everyone are enforced by the database, not only the UI.

alter table public.cv_direct_messages
  add column if not exists deleted_at timestamptz;

create table if not exists public.cv_message_hidden_for (
  message_id uuid not null references public.cv_direct_messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  hidden_at timestamptz not null default now(),
  primary key (message_id, user_id)
);
create index if not exists cv_message_hidden_for_user_idx
  on public.cv_message_hidden_for(user_id, hidden_at desc);

alter table public.cv_message_hidden_for enable row level security;
revoke all on public.cv_message_hidden_for from anon;
grant select, insert, delete on public.cv_message_hidden_for to authenticated;

drop policy if exists "CV users read their hidden messages" on public.cv_message_hidden_for;
create policy "CV users read their hidden messages"
on public.cv_message_hidden_for for select to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "CV users hide messages for themselves" on public.cv_message_hidden_for;
create policy "CV users hide messages for themselves"
on public.cv_message_hidden_for for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.cv_direct_messages m
    where m.id = cv_message_hidden_for.message_id
      and exists (
        select 1 from public.cv_conversations c
        where c.id = m.conversation_id
          and (
            (not c.is_group and ((select auth.uid()) = c.user_a or (select auth.uid()) = c.user_b))
            or (c.is_group and private.cv_is_conversation_member(c.id))
          )
      )
  )
);

drop policy if exists "CV users unhide their own messages" on public.cv_message_hidden_for;
create policy "CV users unhide their own messages"
on public.cv_message_hidden_for for delete to authenticated
using (user_id = (select auth.uid()));

drop policy if exists "CV participants read direct messages" on public.cv_direct_messages;
create policy "CV participants read direct messages"
on public.cv_direct_messages for select to authenticated
using (
  not exists (
    select 1 from public.cv_message_hidden_for h
    where h.message_id = cv_direct_messages.id and h.user_id = (select auth.uid())
  )
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_direct_messages.conversation_id
      and (
        (not c.is_group and ((select auth.uid()) = c.user_a or (select auth.uid()) = c.user_b))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

-- Private helpers do the sensitive mutations. Public RPC wrappers below are invoker-only.
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

  select * into v_message
  from public.cv_direct_messages
  where id = p_message_id
  for update;

  if not found or v_message.sender_id <> v_user then
    raise exception 'You can only edit your own messages';
  end if;
  if v_message.deleted_at is not null then raise exception 'Deleted messages cannot be edited'; end if;
  if v_message.created_at < now() - interval '5 minutes' then
    raise exception 'Messages can only be edited within five minutes';
  end if;

  update public.cv_direct_messages
  set body = v_body, edited_at = now()
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
  select * into v_message
  from public.cv_direct_messages
  where id = p_message_id
  for update;

  if not found or v_message.sender_id <> v_user then
    raise exception 'You can only delete your own messages for everyone';
  end if;
  if v_message.deleted_at is not null then return; end if;
  if v_message.created_at < now() - interval '5 minutes' then
    raise exception 'Delete for everyone is only available within five minutes';
  end if;

  update public.cv_direct_messages
  set body = 'This message was deleted',
      deleted_at = now(),
      edited_at = null,
      attachment_path = null,
      attachment_name = null,
      attachment_mime = null,
      attachment_size = null
  where id = p_message_id and sender_id = v_user;
end;
$cv$;

revoke all on function private.cv_edit_direct_message(uuid, text) from public, anon;
revoke all on function private.cv_delete_direct_message_everyone(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.cv_edit_direct_message(uuid, text) to authenticated;
grant execute on function private.cv_delete_direct_message_everyone(uuid) to authenticated;

create or replace function public.cv_edit_direct_message(p_message_id uuid, p_body text)
returns void
language sql
security invoker
set search_path = public, pg_temp
as $cv$ select private.cv_edit_direct_message(p_message_id, p_body); $cv$;

create or replace function public.cv_delete_direct_message_everyone(p_message_id uuid)
returns void
language sql
security invoker
set search_path = public, pg_temp
as $cv$ select private.cv_delete_direct_message_everyone(p_message_id); $cv$;

revoke all on function public.cv_edit_direct_message(uuid, text) from public, anon;
revoke all on function public.cv_delete_direct_message_everyone(uuid) from public, anon;
grant execute on function public.cv_edit_direct_message(uuid, text) to authenticated;
grant execute on function public.cv_delete_direct_message_everyone(uuid) to authenticated;

-- Replies are threaded by the existing community_comments.parent_id column.
create index if not exists community_comments_parent_created_idx
  on public.community_comments(parent_id, created_at)
  where parent_id is not null;
