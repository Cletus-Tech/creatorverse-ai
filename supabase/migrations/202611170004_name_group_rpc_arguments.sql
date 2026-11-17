-- Give the PostgREST-facing wrappers explicit parameter names.
drop function if exists public.cv_add_group_members(uuid,uuid[]);
drop function if exists public.cv_remove_group_member(uuid,uuid);
drop function if exists public.cv_update_group_member_role(uuid,uuid,text);
drop function if exists public.cv_leave_group(uuid);

create function public.cv_add_group_members(p_conversation_id uuid,p_member_ids uuid[])
returns integer language sql security invoker set search_path=''
as $cv$ select private.cv_add_group_members(p_conversation_id,p_member_ids); $cv$;

create function public.cv_remove_group_member(p_conversation_id uuid,p_member_id uuid)
returns void language sql security invoker set search_path=''
as $cv$ select private.cv_remove_group_member(p_conversation_id,p_member_id); $cv$;

create function public.cv_update_group_member_role(p_conversation_id uuid,p_member_id uuid,p_new_role text)
returns void language sql security invoker set search_path=''
as $cv$ select private.cv_update_group_member_role(p_conversation_id,p_member_id,p_new_role); $cv$;

create function public.cv_leave_group(p_conversation_id uuid)
returns void language sql security invoker set search_path=''
as $cv$ select private.cv_leave_group(p_conversation_id); $cv$;

revoke all on function public.cv_add_group_members(uuid,uuid[]) from public,anon;
revoke all on function public.cv_remove_group_member(uuid,uuid) from public,anon;
revoke all on function public.cv_update_group_member_role(uuid,uuid,text) from public,anon;
revoke all on function public.cv_leave_group(uuid) from public,anon;
grant execute on function public.cv_add_group_members(uuid,uuid[]) to authenticated;
grant execute on function public.cv_remove_group_member(uuid,uuid) to authenticated;
grant execute on function public.cv_update_group_member_role(uuid,uuid,text) to authenticated;
grant execute on function public.cv_leave_group(uuid) to authenticated;
