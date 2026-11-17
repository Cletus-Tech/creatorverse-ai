-- Respect existing block relationships when admins invite new group members.
create or replace function private.cv_add_group_members(p_conversation_id uuid,p_member_ids uuid[])
returns integer language plpgsql security definer set search_path=''
as $cv$
declare v_uid uuid:=auth.uid(); v_is_group boolean; v_added integer:=0;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 if p_member_ids is null or cardinality(p_member_ids)<1 or cardinality(p_member_ids)>50 then raise exception 'Choose between 1 and 50 members'; end if;
 select c.is_group into v_is_group from public.cv_conversations c where c.id=p_conversation_id;
 if coalesce(v_is_group,false) is not true then raise exception 'Group not found'; end if;
 if not exists(select 1 from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.user_id=v_uid and m.member_role='admin') then raise exception 'Only group admins can add members'; end if;
 if v_uid=any(p_member_ids) then raise exception 'You are already in this group'; end if;
 if exists(select 1 from unnest(p_member_ids) x where x is null) then raise exception 'Invalid member selection'; end if;
 if exists(
   select 1 from unnest(p_member_ids) chosen(member_id)
   join public.community_blocks b on
     (b.blocker_id=v_uid and b.blocked_id=chosen.member_id)
     or (b.blocker_id=chosen.member_id and b.blocked_id=v_uid)
 ) then raise exception 'A selected member has a block relationship with you'; end if;
 insert into public.cv_conversation_members(conversation_id,user_id,member_role,added_by)
 select p_conversation_id,x,'member',v_uid from (select distinct unnest(p_member_ids) as x) chosen
 where exists(select 1 from auth.users u where u.id=chosen.x)
 on conflict(conversation_id,user_id) do nothing;
 get diagnostics v_added=row_count; return v_added;
end; $cv$;
revoke all on function private.cv_add_group_members(uuid,uuid[]) from public,anon;
grant execute on function private.cv_add_group_members(uuid,uuid[]) to authenticated;
