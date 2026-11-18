-- Notify every member of a group conversation when a new message arrives.
-- Direct-message notification behaviour remains unchanged.
create or replace function private.cv_notify_direct_message()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_user_a uuid;
  v_user_b uuid;
  v_is_group boolean;
  v_group_name text;
  v_recipient uuid;
  v_sender_name text;
  v_preview text;
begin
  select c.user_a, c.user_b, c.is_group, c.group_name
    into v_user_a, v_user_b, v_is_group, v_group_name
  from public.cv_conversations c
  where c.id = new.conversation_id;

  if coalesce(v_is_group, false) then
    select coalesce(nullif(p.full_name, ''), nullif(p.username, ''), 'Someone')
      into v_sender_name
    from public.public_profiles p
    where p.id = new.sender_id;

    v_preview := case
      when new.attachment_path is not null then 'Sent an attachment'
      else left(coalesce(new.body, 'Sent a message'), 140)
    end;

    insert into public.cv_notifications
      (user_id, actor_id, type, title, body, href, entity_type, entity_id)
    select
      member.user_id,
      new.sender_id,
      'message',
      coalesce(nullif(v_group_name, ''), 'Group message'),
      coalesce(v_sender_name, 'Someone') || ': ' || v_preview,
      'messages.html',
      'conversation',
      new.conversation_id
    from public.cv_conversation_members member
    where member.conversation_id = new.conversation_id
      and member.user_id <> new.sender_id;

    return new;
  end if;

  v_recipient := case
    when v_user_a = new.sender_id then v_user_b
    when v_user_b = new.sender_id then v_user_a
    else null
  end;

  if v_recipient is null or v_recipient = new.sender_id then
    return new;
  end if;

  select coalesce(nullif(p.full_name, ''), nullif(p.username, ''), 'Someone')
    into v_sender_name
  from public.profiles p
  where p.id = new.sender_id;

  v_preview := case
    when new.attachment_path is not null then 'Sent you an attachment'
    else left(coalesce(new.body, 'Sent you a message'), 140)
  end;

  insert into public.cv_notifications
    (user_id, actor_id, type, title, body, href, entity_type, entity_id)
  values
    (v_recipient, new.sender_id, 'message',
     coalesce(v_sender_name, 'Someone') || ' sent you a message',
     v_preview, 'messages.html', 'conversation', new.conversation_id);

  return new;
end;
$function$;
