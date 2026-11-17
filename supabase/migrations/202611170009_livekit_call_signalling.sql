-- Secure, persistent 1:1 call signalling for CreatorVerse.
-- Call metadata is visible only to the two participants; media tokens are minted server-side.

create table if not exists public.cv_call_invites (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.cv_conversations(id) on delete cascade,
  caller_id uuid not null references auth.users(id) on delete cascade,
  callee_id uuid not null references auth.users(id) on delete cascade,
  mode text not null check (mode in ('audio','video')),
  status text not null default 'ringing'
    check (status in ('ringing','accepted','declined','cancelled','ended','missed')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '45 seconds'),
  answered_at timestamptz,
  ended_at timestamptz,
  constraint cv_call_invites_distinct_users check (caller_id <> callee_id)
);

create index if not exists cv_call_invites_callee_recent_idx
  on public.cv_call_invites(callee_id, created_at desc);
create index if not exists cv_call_invites_conversation_recent_idx
  on public.cv_call_invites(conversation_id, created_at desc);

alter table public.cv_call_invites enable row level security;
revoke all on table public.cv_call_invites from anon, authenticated;
grant select on table public.cv_call_invites to authenticated;
grant insert (conversation_id, caller_id, callee_id, mode)
  on table public.cv_call_invites to authenticated;

drop policy if exists "CV call participants read own invites" on public.cv_call_invites;
create policy "CV call participants read own invites"
on public.cv_call_invites for select to authenticated
using (caller_id = (select auth.uid()) or callee_id = (select auth.uid()));

drop policy if exists "CV direct participants create call invites" on public.cv_call_invites;
create policy "CV direct participants create call invites"
on public.cv_call_invites for insert to authenticated
with check (
  caller_id = (select auth.uid())
  and exists (
    select 1
    from public.cv_conversations c
    where c.id = cv_call_invites.conversation_id
      and not c.is_group
      and (
        (c.user_a = (select auth.uid()) and c.user_b = cv_call_invites.callee_id)
        or
        (c.user_b = (select auth.uid()) and c.user_a = cv_call_invites.callee_id)
      )
      and not exists (
        select 1 from public.community_blocks b
        where
          (b.blocker_id = (select auth.uid()) and b.blocked_id = cv_call_invites.callee_id)
          or
          (b.blocked_id = (select auth.uid()) and b.blocker_id = cv_call_invites.callee_id)
      )
  )
);

create or replace function public.cv_create_call_invite(
  p_conversation_id uuid,
  p_callee_id uuid,
  p_mode text
)
returns uuid
language plpgsql
security invoker
set search_path = public, pg_temp
as $cv$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;
  if p_mode not in ('audio','video') then
    raise exception 'Call mode must be audio or video.';
  end if;
  insert into public.cv_call_invites(conversation_id,caller_id,callee_id,mode)
  values(p_conversation_id,auth.uid(),p_callee_id,p_mode)
  returning id into v_id;
  return v_id;
end;
$cv$;
revoke all on function public.cv_create_call_invite(uuid,uuid,text) from public, anon;
grant execute on function public.cv_create_call_invite(uuid,uuid,text) to authenticated;

create or replace function public.cv_get_call_invite(p_call_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $cv$
  select to_jsonb(c)
  from public.cv_call_invites c
  where c.id = p_call_id;
$cv$;
revoke all on function public.cv_get_call_invite(uuid) from public, anon;
grant execute on function public.cv_get_call_invite(uuid) to authenticated;

create or replace function private.cv_set_call_invite_status(
  p_call_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $cv$
declare
  v_call public.cv_call_invites%rowtype;
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Authentication required.';
  end if;
  if p_status not in ('accepted','declined','cancelled','ended','missed') then
    raise exception 'Invalid call status.';
  end if;
  select * into v_call
  from public.cv_call_invites
  where id = p_call_id
  for update;
  if not found or v_user not in (v_call.caller_id,v_call.callee_id) then
    raise exception 'Call invite not found.';
  end if;
  if p_status in ('accepted','declined','missed') then
    if v_user <> v_call.callee_id or v_call.status <> 'ringing' then
      raise exception 'Only the invited participant can answer a ringing call.';
    end if;
  elsif p_status = 'cancelled' then
    if v_user <> v_call.caller_id or v_call.status <> 'ringing' then
      raise exception 'Only the caller can cancel a ringing call.';
    end if;
  elsif p_status = 'ended' then
    if v_call.status not in ('ringing','accepted') then
      raise exception 'This call has already ended.';
    end if;
  end if;
  update public.cv_call_invites
  set status = p_status,
      answered_at = case when p_status = 'accepted' then now() else answered_at end,
      ended_at = case when p_status in ('declined','cancelled','ended','missed') then now() else ended_at end
  where id = p_call_id;
end;
$cv$;
revoke all on function private.cv_set_call_invite_status(uuid,text) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.cv_set_call_invite_status(uuid,text) to authenticated;

create or replace function public.cv_set_call_invite_status(
  p_call_id uuid,
  p_status text
)
returns void
language sql
security invoker
set search_path = public, pg_temp
as $cv$
  select private.cv_set_call_invite_status(p_call_id,p_status);
$cv$;
revoke all on function public.cv_set_call_invite_status(uuid,text) from public, anon;
grant execute on function public.cv_set_call_invite_status(uuid,text) to authenticated;

alter publication supabase_realtime add table public.cv_call_invites;
