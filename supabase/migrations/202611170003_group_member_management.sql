-- Secure group member management for CreatorVerse.
-- Privileged implementations stay in the non-exposed private schema.
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
 insert into public.cv_conversation_members(conversation_id,user_id,member_role,added_by)
 select p_conversation_id,x,'member',v_uid from (select distinct unnest(p_member_ids) as x) chosen
 where exists(select 1 from auth.users u where u.id=chosen.x)
 on conflict(conversation_id,user_id) do nothing;
 get diagnostics v_added=row_count; return v_added;
end; $cv$;

create or replace function private.cv_remove_group_member(p_conversation_id uuid,p_member_id uuid)
returns void language plpgsql security definer set search_path=''
as $cv$
declare v_uid uuid:=auth.uid(); v_role text; v_admin_count integer;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.user_id=v_uid and m.member_role='admin') then raise exception 'Only group admins can remove members'; end if;
 select m.member_role into v_role from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.user_id=p_member_id;
 if v_role is null then raise exception 'Member not found'; end if;
 if v_role='admin' then
  select count(*) into v_admin_count from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.member_role='admin';
  if v_admin_count<=1 then raise exception 'Promote another admin before removing the last admin'; end if;
 end if;
 delete from public.cv_conversation_members where conversation_id=p_conversation_id and user_id=p_member_id;
end; $cv$;

create or replace function private.cv_update_group_member_role(p_conversation_id uuid,p_member_id uuid,p_new_role text)
returns void language plpgsql security definer set search_path=''
as $cv$
declare v_uid uuid:=auth.uid(); v_old_role text; v_admin_count integer;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 if p_new_role not in ('admin','member') then raise exception 'Invalid member role'; end if;
 if not exists(select 1 from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.user_id=v_uid and m.member_role='admin') then raise exception 'Only group admins can change roles'; end if;
 select m.member_role into v_old_role from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.user_id=p_member_id;
 if v_old_role is null then raise exception 'Member not found'; end if;
 if v_old_role='admin' and p_new_role='member' then
  select count(*) into v_admin_count from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.member_role='admin';
  if v_admin_count<=1 then raise exception 'A group must keep at least one admin'; end if;
 end if;
 update public.cv_conversation_members set member_role=p_new_role where conversation_id=p_conversation_id and user_id=p_member_id;
end; $cv$;

create or replace function private.cv_leave_group(p_conversation_id uuid)
returns void language plpgsql security definer set search_path=''
as $cv$
declare v_uid uuid:=auth.uid(); v_role text; v_admin_count integer;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 select m.member_role into v_role from public.cv_conversation_members m join public.cv_conversations c on c.id=m.conversation_id and c.is_group=true
 where m.conversation_id=p_conversation_id and m.user_id=v_uid;
 if v_role is null then raise exception 'You are not a member of this group'; end if;
 if v_role='admin' then
  select count(*) into v_admin_count from public.cv_conversation_members m where m.conversation_id=p_conversation_id and m.member_role='admin';
  if v_admin_count<=1 then raise exception 'Promote another admin before leaving this group'; end if;
 end if;
 delete from public.cv_conversation_members where conversation_id=p_conversation_id and user_id=v_uid;
end; $cv$;

revoke all on function private.cv_add_group_members(uuid,uuid[]) from public,anon;
revoke all on function private.cv_remove_group_member(uuid,uuid) from public,anon;
revoke all on function private.cv_update_group_member_role(uuid,uuid,text) from public,anon;
revoke all on function private.cv_leave_group(uuid) from public,anon;
grant execute on function private.cv_add_group_members(uuid,uuid[]) to authenticated;
grant execute on function private.cv_remove_group_member(uuid,uuid) to authenticated;
grant execute on function private.cv_update_group_member_role(uuid,uuid,text) to authenticated;
grant execute on function private.cv_leave_group(uuid) to authenticated;

create or replace function public.cv_add_group_members(uuid,uuid[])
returns integer language sql security invoker set search_path='' as $cv$ select private.cv_add_group_members($1,$2); $cv$;
create or replace function public.cv_remove_group_member(uuid,uuid)
returns void language sql security invoker set search_path='' as $cv$ select private.cv_remove_group_member($1,$2); $cv$;
create or replace function public.cv_update_group_member_role(uuid,uuid,text)
returns void language sql security invoker set search_path='' as $cv$ select private.cv_update_group_member_role($1,$2,$3); $cv$;
create or replace function public.cv_leave_group(uuid)
returns void language sql security invoker set search_path='' as $cv$ select private.cv_leave_group($1); $cv$;

revoke all on function public.cv_add_group_members(uuid,uuid[]) from public,anon;
revoke all on function public.cv_remove_group_member(uuid,uuid) from public,anon;
revoke all on function public.cv_update_group_member_role(uuid,uuid,text) from public,anon;
revoke all on function public.cv_leave_group(uuid) from public,anon;
grant execute on function public.cv_add_group_members(uuid,uuid[]) to authenticated;
grant execute on function public.cv_remove_group_member(uuid,uuid) to authenticated;
grant execute on function public.cv_update_group_member_role(uuid,uuid,text) to authenticated;
grant execute on function public.cv_leave_group(uuid) to authenticated;
