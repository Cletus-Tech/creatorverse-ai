-- CreatorVerse scheduled learning sessions and explicit check-ins
create table if not exists public.academy_learning_sessions (id uuid primary key default gen_random_uuid(), course_id uuid not null references public.courses(id) on delete cascade, title text not null check (char_length(title) between 3 and 140), description text not null default '', starts_at timestamptz not null, ends_at timestamptz not null, created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), check (ends_at > starts_at));
create index if not exists academy_learning_sessions_course_start_idx on public.academy_learning_sessions(course_id,starts_at);
create table if not exists public.academy_learning_checkins (id uuid primary key default gen_random_uuid(), session_id uuid not null references public.academy_learning_sessions(id) on delete cascade, user_id uuid not null references auth.users(id) on delete cascade, checked_in_at timestamptz not null default now(), unique(session_id,user_id));
create index if not exists academy_learning_checkins_user_idx on public.academy_learning_checkins(user_id,checked_in_at desc);
alter table public.academy_learning_sessions enable row level security;
alter table public.academy_learning_checkins enable row level security;
revoke all on public.academy_learning_sessions, public.academy_learning_checkins from public, anon, authenticated;
grant all on public.academy_learning_sessions, public.academy_learning_checkins to service_role;
create or replace function public.admin_create_learning_session(p_course_id uuid,p_title text,p_description text,p_starts_at timestamptz,p_ends_at timestamptz) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_id uuid; begin
if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
if not exists(select 1 from public.courses where id=p_course_id) then raise exception 'Course not found'; end if;
if p_title is null or char_length(trim(p_title)) not between 3 and 140 then raise exception 'Session title must be 3–140 characters'; end if;
if p_starts_at is null or p_ends_at is null or p_ends_at<=p_starts_at then raise exception 'A valid session start and end time are required'; end if;
if p_ends_at>now()+interval '180 days' then raise exception 'Sessions cannot be scheduled more than 180 days ahead'; end if;
insert into public.academy_learning_sessions(course_id,title,description,starts_at,ends_at,created_by) values(p_course_id,trim(p_title),coalesce(p_description,''),p_starts_at,p_ends_at,auth.uid()) returning id into v_id; return v_id; end $$;
create or replace function public.admin_list_learning_sessions(p_course_id uuid default null) returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v jsonb; begin
if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'course_id',s.course_id,'course_title',c.title,'title',s.title,'description',s.description,'starts_at',s.starts_at,'ends_at',s.ends_at,'created_at',s.created_at,'enrolled_count',(select count(*) from public.enrolments e where e.course_id=s.course_id),'checked_in_count',(select count(*) from public.academy_learning_checkins ci where ci.session_id=s.id),'missed_count',(select count(*) from public.enrolments e where e.course_id=s.course_id and s.ends_at<now() and not exists(select 1 from public.academy_learning_checkins ci where ci.session_id=s.id and ci.user_id=e.user_id)) order by s.starts_at desc),'[]'::jsonb) into v from public.academy_learning_sessions s join public.courses c on c.id=s.course_id where p_course_id is null or s.course_id=p_course_id; return v; end $$;
create or replace function public.student_get_my_learning_sessions() returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_user uuid:=auth.uid(); v jsonb; begin
if v_user is null then raise exception 'Authentication required'; end if;
if not exists(select 1 from public.profiles where id=v_user and role='student') then raise exception 'Student access required'; end if;
select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'course_id',s.course_id,'course_title',c.title,'title',s.title,'description',s.description,'starts_at',s.starts_at,'ends_at',s.ends_at,'checked_in_at',ci.checked_in_at,'status',case when ci.id is not null then 'checked_in' when s.ends_at<now() then 'missed' when s.starts_at<=now() and s.ends_at>=now() then 'open' else 'upcoming' end) order by s.starts_at),'[]'::jsonb) into v from public.academy_learning_sessions s join public.courses c on c.id=s.course_id join public.enrolments e on e.course_id=s.course_id and e.user_id=v_user left join public.academy_learning_checkins ci on ci.session_id=s.id and ci.user_id=v_user where s.ends_at>=now()-interval '30 days' and s.starts_at<=now()+interval '90 days'; return v; end $$;
create or replace function public.student_check_in_learning_session(p_session_id uuid) returns timestamptz language plpgsql security definer set search_path=pg_catalog,public as $$
declare v_user uuid:=auth.uid(); v_session public.academy_learning_sessions%rowtype; v_time timestamptz; begin
if v_user is null then raise exception 'Authentication required'; end if;
if not exists(select 1 from public.profiles where id=v_user and role='student') then raise exception 'Student access required'; end if;
select * into v_session from public.academy_learning_sessions where id=p_session_id for update;
if not found then raise exception 'Session not found'; end if;
if not exists(select 1 from public.enrolments where user_id=v_user and course_id=v_session.course_id) then raise exception 'You are not enrolled in this course'; end if;
if now()<v_session.starts_at or now()>v_session.ends_at then raise exception 'Check-in is available only during the scheduled session'; end if;
insert into public.academy_learning_checkins(session_id,user_id) values(p_session_id,v_user) on conflict(session_id,user_id) do update set checked_in_at=public.academy_learning_checkins.checked_in_at returning checked_in_at into v_time; return v_time; end $$;
revoke all on function public.admin_create_learning_session(uuid,text,text,timestamptz,timestamptz) from public,anon;
revoke all on function public.admin_list_learning_sessions(uuid) from public,anon;
revoke all on function public.student_get_my_learning_sessions() from public,anon;
revoke all on function public.student_check_in_learning_session(uuid) from public,anon;
grant execute on function public.admin_create_learning_session(uuid,text,text,timestamptz,timestamptz) to authenticated;
grant execute on function public.admin_list_learning_sessions(uuid) to authenticated;
grant execute on function public.student_get_my_learning_sessions() to authenticated;
grant execute on function public.student_check_in_learning_session(uuid) to authenticated;
