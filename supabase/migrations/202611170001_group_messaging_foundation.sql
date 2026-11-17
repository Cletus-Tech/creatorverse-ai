-- CreatorVerse group messaging foundation.
-- Additive migration: existing direct conversations and messages remain unchanged.

alter table public.cv_conversations
  add column if not exists is_group boolean not null default false,
  add column if not exists group_name text,
  add column if not exists group_avatar_path text;

alter table public.cv_conversations
  drop constraint if exists cv_conversations_group_name_length_check;
alter table public.cv_conversations
  add constraint cv_conversations_group_name_length_check
  check (group_name is null or char_length(btrim(group_name)) between 2 and 80);

create table if not exists public.cv_conversation_members (
  conversation_id uuid not null references public.cv_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  member_role text not null default 'member' check (member_role in ('admin','member')),
  added_by uuid not null references auth.users(id),
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index if not exists cv_conversation_members_user_idx
  on public.cv_conversation_members(user_id, joined_at desc);
create index if not exists cv_conversations_group_activity_idx
  on public.cv_conversations(is_group, last_message_at desc)
  where is_group = true;

alter table public.cv_conversation_members enable row level security;
revoke all on table public.cv_conversation_members from anon;
grant select on table public.cv_conversation_members to authenticated;

-- Private SECURITY DEFINER helper prevents recursive membership RLS checks.
create or replace function private.cv_is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $cv$
  select exists (
    select 1 from public.cv_conversation_members m
    where m.conversation_id = p_conversation_id
      and m.user_id = (select auth.uid())
  );
$cv$;
revoke all on function private.cv_is_conversation_member(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.cv_is_conversation_member(uuid) to authenticated;

drop policy if exists "CV conversation participants read" on public.cv_conversations;
create policy "CV conversation participants read"
on public.cv_conversations for select to authenticated
using (
  (not is_group and (auth.uid() = user_a or auth.uid() = user_b))
  or
  (is_group and private.cv_is_conversation_member(id))
);

drop policy if exists "CV users start direct conversations" on public.cv_conversations;
create policy "CV users start direct conversations"
on public.cv_conversations for insert to authenticated
with check (
  not is_group
  and created_by = auth.uid()
  and (auth.uid() = user_a or auth.uid() = user_b)
  and not exists (
    select 1 from public.community_blocks b
    where
      (b.blocker_id = auth.uid() and b.blocked_id =
        case when user_a = auth.uid() then user_b else user_a end)
      or
      (b.blocked_id = auth.uid() and b.blocker_id =
        case when user_a = auth.uid() then user_b else user_a end)
  )
);

drop policy if exists "CV conversation members read own groups" on public.cv_conversation_members;
create policy "CV conversation members read own groups"
on public.cv_conversation_members for select to authenticated
using (
  private.cv_is_conversation_member(cv_conversation_members.conversation_id)
);

-- Membership writes are intentionally performed through the security-definer RPC below.
revoke insert, update, delete on public.cv_conversation_members from anon, authenticated;

drop policy if exists "CV participants read direct messages" on public.cv_direct_messages;
create policy "CV participants read direct messages"
on public.cv_direct_messages for select to authenticated
using (
  exists (
    select 1 from public.cv_conversations c
    where c.id = cv_direct_messages.conversation_id
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or
        (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "CV participants send direct messages" on public.cv_direct_messages;
create policy "CV participants send direct messages"
on public.cv_direct_messages for insert to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_direct_messages.conversation_id
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b)
          and not exists (
            select 1 from public.community_blocks b
            where
              (b.blocker_id = auth.uid() and b.blocked_id =
                case when c.user_a = auth.uid() then c.user_b else c.user_a end)
              or
              (b.blocked_id = auth.uid() and b.blocker_id =
                case when c.user_a = auth.uid() then c.user_b else c.user_a end)
          ))
        or
        (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "CV recipients mark messages read" on public.cv_direct_messages;
create policy "CV recipients mark messages read"
on public.cv_direct_messages for update to authenticated
using (
  sender_id <> auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_direct_messages.conversation_id
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or
        (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
)
with check (
  sender_id <> auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_direct_messages.conversation_id
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or
        (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "chat preferences owner read" on public.cv_chat_preferences;
create policy "chat preferences owner read"
on public.cv_chat_preferences for select to authenticated
using (
  user_id = auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_chat_preferences.conversation_id
      and (
        (not c.is_group and (c.user_a = auth.uid() or c.user_b = auth.uid()))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "chat preferences owner insert" on public.cv_chat_preferences;
create policy "chat preferences owner insert"
on public.cv_chat_preferences for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_chat_preferences.conversation_id
      and (
        (not c.is_group and (c.user_a = auth.uid() or c.user_b = auth.uid()))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "chat preferences owner update" on public.cv_chat_preferences;
create policy "chat preferences owner update"
on public.cv_chat_preferences for update to authenticated
using (
  user_id = auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_chat_preferences.conversation_id
      and (
        (not c.is_group and (c.user_a = auth.uid() or c.user_b = auth.uid()))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
)
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.cv_conversations c
    where c.id = cv_chat_preferences.conversation_id
      and (
        (not c.is_group and (c.user_a = auth.uid() or c.user_b = auth.uid()))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

create or replace function public.cv_create_group_conversation(
  p_group_name text,
  p_member_ids uuid[]
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $cv$
declare
  v_user uuid := auth.uid();
  v_conversation_id uuid;
  v_name text := btrim(coalesce(p_group_name, ''));
  v_member_count integer;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if char_length(v_name) < 2 or char_length(v_name) > 80 then
    raise exception 'Group name must be between 2 and 80 characters';
  end if;
  if p_member_ids is null or cardinality(p_member_ids) < 1 or cardinality(p_member_ids) > 99 then
    raise exception 'Choose between 1 and 99 other members';
  end if;
  if v_user = any(p_member_ids) then
    raise exception 'Do not include yourself in the member list';
  end if;

  select count(distinct invited.user_id) into v_member_count
  from unnest(p_member_ids) as invited(user_id);
  if v_member_count < 1 then
    raise exception 'Choose at least one other member';
  end if;

  if exists (
    select 1
    from unnest(p_member_ids) as invited(user_id)
    where exists (
      select 1 from public.community_blocks b
      where (b.blocker_id = v_user and b.blocked_id = invited.user_id)
         or (b.blocker_id = invited.user_id and b.blocked_id = v_user)
    )
  ) then
    raise exception 'A selected member cannot be added because of a block setting';
  end if;

  insert into public.cv_conversations(user_a, user_b, created_by, is_group, group_name)
  values (v_user, v_user, v_user, true, v_name)
  returning id into v_conversation_id;

  insert into public.cv_conversation_members(conversation_id, user_id, member_role, added_by)
  values (v_conversation_id, v_user, 'admin', v_user)
  on conflict do nothing;

  insert into public.cv_conversation_members(conversation_id, user_id, member_role, added_by)
  select v_conversation_id, invited.user_id, 'member', v_user
  from (select distinct unnest(p_member_ids) as user_id) invited
  where exists (select 1 from auth.users u where u.id = invited.user_id)
  on conflict do nothing;

  if (select count(*) from public.cv_conversation_members m where m.conversation_id = v_conversation_id) < 2 then
    raise exception 'At least two valid members are required';
  end if;

  return v_conversation_id;
end;
$cv$;

revoke all on function public.cv_create_group_conversation(text, uuid[]) from public, anon;
grant execute on function public.cv_create_group_conversation(text, uuid[]) to authenticated;

comment on table public.cv_conversation_members is
  'Membership and roles for CreatorVerse group conversations; writes are restricted to trusted RPCs.';
