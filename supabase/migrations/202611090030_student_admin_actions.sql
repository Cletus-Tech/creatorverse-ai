create table if not exists public.academy_student_admin_actions (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 course_id uuid references public.courses(id) on delete set null,
 action_type text not null check (action_type in ('academic_warning','private_note','commendation','progression_review')),
 title text not null check (char_length(title) between 3 and 120),
 body text not null check (char_length(body) between 3 and 3000),
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create index if not exists academy_student_admin_actions_student_created_idx on public.academy_student_admin_actions(student_id,created_at desc);
alter table public.academy_student_admin_actions enable row level security;
revoke all on public.academy_student_admin_actions from anon,authenticated;
create or replace function public.admin_add_student_action(p_student_id uuid,p_course_id uuid,p_action_type text,p_title text,p_body text)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_id uuid;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required' using errcode='42501'; end if;
 if not exists(select 1 from public.profiles where id=p_student_id and role='student') then raise exception 'Student account not found'; end if;
 if p_action_type not in ('academic_warning','private_note','commendation','progression_review') then raise exception 'Unsupported action type'; end if;
 if p_title is null or char_length(trim(p_title)) not between 3 and 120 or p_body is null or char_length(trim(p_body)) not between 3 and 3000 then raise exception 'Enter a title and note (3–3000 characters)'; end if;
 if p_course_id is not null and not exists(select 1 from public.enrolments where user_id=p_student_id and course_id=p_course_id) then raise exception 'Student is not enrolled in the selected course'; end if;
 insert into public.academy_student_admin_actions(student_id,course_id,action_type,title,body,created_by)
 values(p_student_id,p_course_id,p_action_type,trim(p_title),trim(p_body),auth.uid()) returning id into v_id;
 return jsonb_build_object('id',v_id,'created_at',now());
end;$function$;
create or replace function public.admin_list_student_actions(p_student_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare result jsonb;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',a.id,'action_type',a.action_type,'title',a.title,'body',a.body,'course_title',c.title,'created_at',a.created_at,'created_by_name',p.full_name) order by a.created_at desc),'[]'::jsonb)
 into result from public.academy_student_admin_actions a left join public.courses c on c.id=a.course_id left join public.profiles p on p.id=a.created_by where a.student_id=p_student_id;
 return result;
end;$function$;
revoke all on function public.admin_add_student_action(uuid,uuid,text,text,text) from public,anon;
revoke all on function public.admin_list_student_actions(uuid) from public,anon;
grant execute on function public.admin_add_student_action(uuid,uuid,text,text,text) to authenticated;
grant execute on function public.admin_list_student_actions(uuid) to authenticated;