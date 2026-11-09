-- CreatorVerse student intervention and follow-up
create table if not exists public.academy_student_interventions (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references auth.users(id) on delete cascade,
 course_id uuid references public.courses(id) on delete set null, title text not null check(char_length(title) between 3 and 140),
 message text not null check(char_length(message) between 3 and 4000), action_required text not null default '',
 due_at timestamptz, status text not null default 'open' check(status in ('open','responded','resolved')),
 student_response text, responded_at timestamptz, resolved_at timestamptz, created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists academy_student_interventions_student_idx on public.academy_student_interventions(student_id,created_at desc);
alter table public.academy_student_interventions enable row level security;
revoke all on public.academy_student_interventions from public,anon,authenticated;
grant all on public.academy_student_interventions to service_role;
create or replace function public.admin_create_student_intervention(p_student_id uuid,p_course_id uuid,p_title text,p_message text,p_action_required text,p_due_at timestamptz default null) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_id uuid; begin
if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
if not exists(select 1 from public.profiles where id=p_student_id and role='student') then raise exception 'Student account not found'; end if;
if p_course_id is not null and not exists(select 1 from public.enrolments where user_id=p_student_id and course_id=p_course_id) then raise exception 'Selected course is not enrolled by this student'; end if;
if p_title is null or char_length(trim(p_title)) not between 3 and 140 then raise exception 'Title must be 3–140 characters'; end if;
if p_message is null or char_length(trim(p_message)) not between 3 and 4000 then raise exception 'Message must be 3–4000 characters'; end if;
if p_due_at is not null and p_due_at<now() then raise exception 'Follow-up deadline must be in the future'; end if;
insert into public.academy_student_interventions(student_id,course_id,title,message,action_required,due_at,created_by) values(p_student_id,p_course_id,trim(p_title),trim(p_message),coalesce(trim(p_action_required),''),p_due_at,auth.uid()) returning id into v_id; return v_id; end $$;
create or replace function public.admin_list_student_interventions(p_student_id uuid) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v jsonb; begin
if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'student_id',i.student_id,'course_id',i.course_id,'course_title',c.title,'title',i.title,'message',i.message,'action_required',i.action_required,'due_at',i.due_at,'status',i.status,'student_response',i.student_response,'responded_at',i.responded_at,'resolved_at',i.resolved_at,'created_at',i.created_at,'created_by_name',p.full_name) order by i.created_at desc),'[]'::jsonb) into v from public.academy_student_interventions i left join public.courses c on c.id=i.course_id left join public.profiles p on p.id=i.created_by where i.student_id=p_student_id; return v; end $$;
create or replace function public.student_get_my_interventions() returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_user uuid:=auth.uid(); v jsonb; begin
if v_user is null then raise exception 'Authentication required'; end if;
if not exists(select 1 from public.profiles where id=v_user and role='student') then raise exception 'Student access required'; end if;
select coalesce(jsonb_agg(jsonb_build_object('id',i.id,'course_title',c.title,'title',i.title,'message',i.message,'action_required',i.action_required,'due_at',i.due_at,'status',i.status,'student_response',i.student_response,'responded_at',i.responded_at,'resolved_at',i.resolved_at,'created_at',i.created_at) order by i.created_at desc),'[]'::jsonb) into v from public.academy_student_interventions i left join public.courses c on c.id=i.course_id where i.student_id=v_user; return v; end $$;
create or replace function public.student_respond_to_intervention(p_intervention_id uuid,p_response text) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_id uuid; begin
if auth.uid() is null then raise exception 'Authentication required'; end if;
if not exists(select 1 from public.profiles where id=auth.uid() and role='student') then raise exception 'Student access required'; end if;
if p_response is null or char_length(trim(p_response)) not between 3 and 3000 then raise exception 'Response must be 3–3000 characters'; end if;
update public.academy_student_interventions set student_response=trim(p_response),responded_at=now(),status='responded',updated_at=now() where id=p_intervention_id and student_id=auth.uid() and status<>'resolved' returning id into v_id;
if v_id is null then raise exception 'Intervention not found or already resolved'; end if; return v_id; end $$;
create or replace function public.admin_update_student_intervention(p_intervention_id uuid,p_status text) returns boolean language plpgsql security definer set search_path=pg_catalog,public as $$
begin
if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
if p_status not in ('open','resolved') then raise exception 'Status must be open or resolved'; end if;
update public.academy_student_interventions set status=p_status,resolved_at=case when p_status='resolved' then now() else null end,updated_at=now() where id=p_intervention_id;
if not found then raise exception 'Intervention not found'; end if; return true; end $$;
revoke all on function public.admin_create_student_intervention(uuid,uuid,text,text,text,timestamptz) from public,anon;
revoke all on function public.admin_list_student_interventions(uuid) from public,anon;
revoke all on function public.student_get_my_interventions() from public,anon;
revoke all on function public.student_respond_to_intervention(uuid,text) from public,anon;
revoke all on function public.admin_update_student_intervention(uuid,text) from public,anon;
grant execute on function public.admin_create_student_intervention(uuid,uuid,text,text,text,timestamptz) to authenticated;
grant execute on function public.admin_list_student_interventions(uuid) to authenticated;
grant execute on function public.student_get_my_interventions() to authenticated;
grant execute on function public.student_respond_to_intervention(uuid,text) to authenticated;
grant execute on function public.admin_update_student_intervention(uuid,text) to authenticated;
