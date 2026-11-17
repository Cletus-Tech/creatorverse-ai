-- Distinguish placing a call from the recipient's phone actually ringing.
-- Calls begin as "calling"; the recipient app moves them to "ringing" when it receives the invite.
alter table public.cv_call_invites alter column status set default 'calling';
alter table public.cv_call_invites drop constraint if exists cv_call_invites_status_check;
alter table public.cv_call_invites add constraint cv_call_invites_status_check
  check (status in ('calling','ringing','accepted','declined','cancelled','ended','missed'));

create or replace function private.cv_set_call_invite_status(p_call_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_call public.cv_call_invites%rowtype;
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required.'; end if;
  if p_status not in ('ringing','accepted','declined','cancelled','ended','missed') then
    raise exception 'Invalid call status.';
  end if;

  select * into v_call from public.cv_call_invites where id=p_call_id for update;
  if not found or v_user not in (v_call.caller_id,v_call.callee_id) then
    raise exception 'Call invite not found.';
  end if;

  if p_status='ringing' then
    if v_user<>v_call.callee_id or v_call.status<>'calling' then
      raise exception 'Only the invited participant can mark a calling invite as ringing.';
    end if;
    if v_call.expires_at<=now() then
      update public.cv_call_invites set status='missed',ended_at=coalesce(ended_at,now()) where id=p_call_id;
      return;
    end if;
  elsif p_status in ('accepted','declined') then
    if v_user<>v_call.callee_id or v_call.status<>'ringing' then
      raise exception 'Only the invited participant can answer a ringing call.';
    end if;
    if v_call.expires_at<=now() then
      update public.cv_call_invites set status='missed',ended_at=coalesce(ended_at,now()) where id=p_call_id;
      return;
    end if;
  elsif p_status='cancelled' then
    if v_user<>v_call.caller_id or v_call.status not in ('calling','ringing') then
      raise exception 'Only the caller can cancel an unanswered call.';
    end if;
  elsif p_status='missed' then
    if v_call.status not in ('calling','ringing') or v_call.expires_at>now()
       or v_user<>v_call.caller_id then
      raise exception 'Only the caller can mark an expired unanswered call as missed.';
    end if;
  elsif p_status='ended' then
    if v_call.status<>'accepted' then
      raise exception 'Only an answered call can be ended.';
    end if;
  end if;

  update public.cv_call_invites
     set status=p_status,
         answered_at=case when p_status='accepted' then now() else answered_at end,
         ended_at=case when p_status in ('declined','cancelled','ended','missed') then now() else ended_at end
   where id=p_call_id;
end;
$function$;

create or replace function private.cv_expire_stale_call_invites()
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_expired_count integer := 0;
begin
  with expired as (
    update public.cv_call_invites c
       set status='missed', ended_at=coalesce(c.ended_at,now())
     where c.status in ('calling','ringing') and c.expires_at<=now()
    returning c.id,c.callee_id,c.mode
  )
  update public.cv_notifications n
     set type='missed_call',
         title=case when e.mode='video' then 'Missed video call' else 'Missed audio call' end,
         body='You missed a call.',
         priority='high'
    from expired e
   where n.entity_type='call' and n.entity_id=e.id
     and n.user_id=e.callee_id and n.type='incoming_call';

  get diagnostics v_expired_count = row_count;
  return v_expired_count;
end;
$function$;
