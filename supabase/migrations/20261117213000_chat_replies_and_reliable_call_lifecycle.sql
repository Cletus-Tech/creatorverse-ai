-- Chat replies, missed-call timeline entries, and authoritative call expiry.
alter table public.cv_direct_messages
  add column if not exists reply_to_id uuid references public.cv_direct_messages(id) on delete set null,
  add column if not exists message_type text not null default 'text',
  add column if not exists call_id uuid references public.cv_call_invites(id) on delete set null;

alter table public.cv_direct_messages
  drop constraint if exists cv_direct_messages_message_type_check;
alter table public.cv_direct_messages
  add constraint cv_direct_messages_message_type_check
  check (message_type in ('text','missed_call'));

create index if not exists cv_direct_messages_reply_to_idx
  on public.cv_direct_messages(reply_to_id) where reply_to_id is not null;
create unique index if not exists cv_direct_messages_missed_call_unique
  on public.cv_direct_messages(call_id)
  where message_type='missed_call' and call_id is not null;

create or replace function private.cv_validate_direct_message_reply()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_conversation_id uuid;
begin
  if new.reply_to_id is null then return new; end if;
  if new.reply_to_id = new.id then
    raise exception 'A message cannot reply to itself.';
  end if;
  select m.conversation_id into v_conversation_id
  from public.cv_direct_messages m
  where m.id = new.reply_to_id;
  if v_conversation_id is null or v_conversation_id <> new.conversation_id then
    raise exception 'Replies must reference a message in the same conversation.';
  end if;
  return new;
end;
$fn$;
revoke all on function private.cv_validate_direct_message_reply() from public, anon, authenticated;

drop trigger if exists cv_validate_direct_message_reply on public.cv_direct_messages;
create trigger cv_validate_direct_message_reply
before insert or update of reply_to_id, conversation_id
on public.cv_direct_messages
for each row execute function private.cv_validate_direct_message_reply();

-- Only callers can mark their own still-ringing call as missed, and only after
-- the server-side expiry. A late answer is converted to missed atomically.
create or replace function private.cv_set_call_invite_status(
  p_call_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_call public.cv_call_invites%rowtype;
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required.'; end if;
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

  if p_status in ('accepted','declined') then
    if v_user <> v_call.callee_id or v_call.status <> 'ringing' then
      raise exception 'Only the invited participant can answer a ringing call.';
    end if;
    if v_call.expires_at <= now() then
      update public.cv_call_invites
      set status='missed', ended_at=coalesce(ended_at,now())
      where id=p_call_id;
      return;
    end if;
  elsif p_status = 'cancelled' then
    if v_user <> v_call.caller_id or v_call.status <> 'ringing' then
      raise exception 'Only the caller can cancel a ringing call.';
    end if;
  elsif p_status = 'missed' then
    if v_call.status <> 'ringing' or v_call.expires_at > now()
       or v_user <> v_call.caller_id then
      raise exception 'Only the caller can mark an expired unanswered call as missed.';
    end if;
  elsif p_status = 'ended' then
    if v_call.status <> 'accepted' then
      raise exception 'Only an answered call can be ended.';
    end if;
  end if;

  update public.cv_call_invites
  set status=p_status,
      answered_at=case when p_status='accepted' then now() else answered_at end,
      ended_at=case when p_status in ('declined','cancelled','ended','missed') then now() else ended_at end
  where id=p_call_id;
end;
$fn$;
revoke all on function private.cv_set_call_invite_status(uuid,text) from public, anon;
grant execute on function private.cv_set_call_invite_status(uuid,text) to authenticated;

create or replace function private.cv_log_missed_call_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $fn$
begin
  if new.status='missed' and old.status is distinct from new.status then
    insert into public.cv_direct_messages
      (conversation_id,sender_id,body,message_type,call_id)
    values
      (new.conversation_id,new.caller_id,
       case when new.mode='video' then 'Missed video call' else 'Missed audio call' end,
       'missed_call',new.id)
    on conflict (call_id) where message_type='missed_call' and call_id is not null
    do nothing;
  end if;
  return new;
end;
$fn$;
revoke all on function private.cv_log_missed_call_message() from public, anon, authenticated;

drop trigger if exists cv_log_missed_call_message on public.cv_call_invites;
create trigger cv_log_missed_call_message
after update of status on public.cv_call_invites
for each row execute function private.cv_log_missed_call_message();

-- Authenticated users may reply to messages but cannot forge system call records.
revoke insert on public.cv_direct_messages from anon;
revoke insert (message_type,call_id) on public.cv_direct_messages from authenticated;
grant insert (conversation_id,sender_id,body,reply_to_id,attachment_path,attachment_name,attachment_mime,attachment_size)
  on public.cv_direct_messages to authenticated;
