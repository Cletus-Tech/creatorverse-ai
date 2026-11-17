-- Keep group creation's privileged implementation out of the exposed public schema.
create or replace function private.cv_create_group_conversation(p_group_name text,p_member_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path=''
as $cv$
declare
 v_user uuid:=auth.uid();
 v_conversation_id uuid;
 v_name text:=btrim(coalesce(p_group_name,''));
 v_member_count integer;
begin
 if v_user is null then raise exception 'Authentication required'; end if;
 if char_length(v_name)<2 or char_length(v_name)>80 then raise exception 'Group name must be between 2 and 80 characters'; end if;
 if p_member_ids is null or cardinality(p_member_ids)<1 or cardinality(p_member_ids)>99 then raise exception 'Choose between 1 and 99 other members'; end if;
 if v_user=any(p_member_ids) then raise exception 'Do not include yourself in the member list'; end if;
 select count(distinct invited.user_id) into v_member_count from unnest(p_member_ids) as invited(user_id);
 if v_member_count<1 then raise exception 'Choose at least one other member'; end if;
 if exists(
  select 1 from unnest(p_member_ids) as invited(user_id)
  where exists(select 1 from public.community_blocks b
    where (b.blocker_id=v_user and b.blocked_id=invited.user_id)
       or (b.blocker_id=invited.user_id and b.blocked_id=v_user))
 ) then raise exception 'A selected member cannot be added because of a block setting'; end if;
 insert into public.cv_conversations(user_a,user_b,created_by,is_group,group_name)
 values(v_user,v_user,v_user,true,v_name) returning id into v_conversation_id;
 insert into public.cv_conversation_members(conversation_id,user_id,member_role,added_by)
 values(v_conversation_id,v_user,'admin',v_user) on conflict do nothing;
 insert into public.cv_conversation_members(conversation_id,user_id,member_role,added_by)
 select v_conversation_id,invited.user_id,'member',v_user
 from (select distinct unnest(p_member_ids) as user_id) invited
 where exists(select 1 from auth.users u where u.id=invited.user_id)
 on conflict do nothing;
 if (select count(*) from public.cv_conversation_members m where m.conversation_id=v_conversation_id)<2 then
  raise exception 'At least two valid members are required';
 end if;
 return v_conversation_id;
end;
$cv$;

revoke all on function private.cv_create_group_conversation(text,uuid[]) from public,anon;
grant execute on function private.cv_create_group_conversation(text,uuid[]) to authenticated;

create or replace function public.cv_create_group_conversation(p_group_name text,p_member_ids uuid[])
returns uuid
language sql
security invoker
set search_path=''
as $cv$ select private.cv_create_group_conversation(p_group_name,p_member_ids); $cv$;

revoke all on function public.cv_create_group_conversation(text,uuid[]) from public,anon;
grant execute on function public.cv_create_group_conversation(text,uuid[]) to authenticated;
