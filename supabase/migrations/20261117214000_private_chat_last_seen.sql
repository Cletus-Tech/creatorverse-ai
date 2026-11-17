-- Last-seen timestamps are exposed only to a member of the same direct chat.
create table if not exists public.cv_presence_last_seen (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_seen_at timestamptz not null default now()
);
alter table public.cv_presence_last_seen enable row level security;
revoke all on public.cv_presence_last_seen from anon, authenticated;

create or replace function public.cv_touch_last_seen()
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required.'; end if;
  insert into public.cv_presence_last_seen(user_id,last_seen_at)
  values(v_user,now())
  on conflict(user_id) do update set last_seen_at=excluded.last_seen_at;
end;
$fn$;
revoke all on function public.cv_touch_last_seen() from public, anon;
grant execute on function public.cv_touch_last_seen() to authenticated;

create or replace function public.cv_get_chat_last_seen(p_user_id uuid)
returns timestamptz
language plpgsql
stable
security definer
set search_path = ''
as $fn$
declare v_user uuid := auth.uid(); v_seen timestamptz;
begin
  if v_user is null then raise exception 'Authentication required.'; end if;
  if p_user_id is null or p_user_id=v_user then return null; end if;
  if not exists (
    select 1 from public.cv_conversations c
    where not c.is_group
      and ((c.user_a=v_user and c.user_b=p_user_id) or (c.user_b=v_user and c.user_a=p_user_id))
  ) then
    raise exception 'Last seen is available only to direct conversation participants.';
  end if;
  if exists (
    select 1 from public.community_blocks b
    where (b.blocker_id=v_user and b.blocked_id=p_user_id)
       or (b.blocker_id=p_user_id and b.blocked_id=v_user)
  ) then return null; end if;
  select s.last_seen_at into v_seen
  from public.cv_presence_last_seen s where s.user_id=p_user_id;
  return v_seen;
end;
$fn$;
revoke all on function public.cv_get_chat_last_seen(uuid) from public, anon;
grant execute on function public.cv_get_chat_last_seen(uuid) to authenticated;
