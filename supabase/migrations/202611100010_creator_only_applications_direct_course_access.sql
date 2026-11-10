-- 2026-11-10: Separate creator/instructor applications from normal course purchases.
-- Normal learners buy/enrol directly. Creator-facing applications retain the admin interview workflow.
-- Existing student application rows and course/payment data are preserved.

alter table public.academy_applications
  add column if not exists application_type text not null default 'student',
  add column if not exists specialty text,
  add column if not exists work_sample_urls text;

alter table public.academy_applications
  drop constraint if exists academy_applications_application_type_check;
alter table public.academy_applications
  add constraint academy_applications_application_type_check
  check (application_type in ('student','creator','instructor','teacher','exhibitor'));

create unique index if not exists academy_applications_one_creator_application_per_user
  on public.academy_applications(user_id)
  where application_type in ('creator','instructor','teacher','exhibitor');

insert into public.courses(slug,title,description,category_slug,level,price_ngn,published,featured,duration_months,study_hours_per_week)
values(
 'creator-partner-application',
 'CreatorVerse Creator & Instructor Application',
 'Internal application pathway for people seeking to create, teach, instruct or exhibit work on CreatorVerse.',
 'internal','Professional',0,false,false,1,1
)
on conflict(slug) do update set
 title=excluded.title,description=excluded.description,published=false,featured=false;

drop policy if exists "courses read" on public.courses;
create policy "courses read" on public.courses for select
using (
 published or public.is_admin()
 or (auth.uid() is not null and slug='creator-partner-application')
);

drop policy if exists "Academy applicants create drafts" on public.academy_applications;
create policy "Academy applicants create drafts"
on public.academy_applications for insert to authenticated
with check (
 user_id=auth.uid() and status='draft'
 and consented_at is not null and privacy_version is not null
 and (
  (application_type='student' and exists(
   select 1 from public.courses c where c.id=academy_applications.course_id and c.published=true
  ))
  or
  (application_type in ('creator','instructor','teacher','exhibitor') and exists(
   select 1 from public.courses c where c.id=academy_applications.course_id
    and c.slug='creator-partner-application' and c.published=false
  ))
 )
);

drop policy if exists "Academy applicants update own drafts" on public.academy_applications;
create policy "Academy applicants update own drafts"
on public.academy_applications for update to authenticated
using (user_id=auth.uid() and status='draft')
with check (
 user_id=auth.uid() and status in ('draft','submitted')
 and consented_at is not null and privacy_version is not null
 and (
  (application_type='student' and exists(
   select 1 from public.courses c where c.id=academy_applications.course_id and c.published=true
  ))
  or
  (application_type in ('creator','instructor','teacher','exhibitor') and exists(
   select 1 from public.courses c where c.id=academy_applications.course_id
    and c.slug='creator-partner-application' and c.published=false
  ))
 )
);

-- Students can view their progress, but only administrators can create or remove verified completions.
drop policy if exists "progress add own" on public.lesson_progress;
drop policy if exists "progress remove own" on public.lesson_progress;

create or replace function public.admin_mark_lesson_completed(
 p_user_id uuid,p_lesson_id uuid,p_completed boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_course uuid;
begin
 if auth.uid() is null or not public.is_admin() then
  raise exception 'Only Academy administrators can verify lesson completion';
 end if;
 select m.course_id into v_course
 from public.lessons l join public.modules m on m.id=l.module_id
 where l.id=p_lesson_id;
 if v_course is null then raise exception 'Lesson not found'; end if;
 if not exists(select 1 from public.enrolments where user_id=p_user_id and course_id=v_course) then
  raise exception 'Student is not enrolled in this course';
 end if;
 if coalesce(p_completed,true) then
  insert into public.lesson_progress(user_id,lesson_id,completed_at)
  values(p_user_id,p_lesson_id,now())
  on conflict(user_id,lesson_id) do update
   set completed_at=coalesce(public.lesson_progress.completed_at,excluded.completed_at);
 else
  update public.lesson_progress set completed_at=null
  where user_id=p_user_id and lesson_id=p_lesson_id;
 end if;
 return jsonb_build_object('student_id',p_user_id,'lesson_id',p_lesson_id,'completed',coalesce(p_completed,true));
end;
$$;
revoke all on function public.admin_mark_lesson_completed(uuid,uuid,boolean) from public,anon;
grant execute on function public.admin_mark_lesson_completed(uuid,uuid,boolean) to authenticated;

create or replace function public.admin_grant_creator_access(p_application_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare v_app public.academy_applications%rowtype;
begin
 if auth.uid() is null or not public.is_admin() then
  raise exception 'Only CreatorVerse administrators can grant creator access';
 end if;
 select * into v_app from public.academy_applications
 where id=p_application_id
  and application_type in ('creator','instructor','teacher','exhibitor')
 for update;
 if not found then raise exception 'Creator application not found'; end if;
 if v_app.status<>'approved' then raise exception 'Approve the application before granting creator access'; end if;
 if not exists(select 1 from public.academy_interviews i
  where i.application_id=v_app.id and i.status='completed' and i.score is not null) then
  raise exception 'Complete and score at least one creator interview assessment first';
 end if;
 update public.profiles set role='creator' where id=v_app.user_id;
 if not found then raise exception 'Applicant profile could not be updated'; end if;
 insert into public.academy_application_events(application_id,actor_id,event_type,from_status,to_status,message,metadata)
 values(v_app.id,auth.uid(),'creator_access_granted','approved','approved',
  'Creator access granted by an administrator after interview assessment.',
  jsonb_build_object('application_type',v_app.application_type,'profile_role','creator'));
 insert into public.academy_audit_log(actor_id,application_id,action,details)
 values(auth.uid(),v_app.id,'creator_access_granted',
  jsonb_build_object('user_id',v_app.user_id,'application_type',v_app.application_type));
 return jsonb_build_object('granted',true,'user_id',v_app.user_id,'role','creator');
end;
$$;
revoke all on function public.admin_grant_creator_access(uuid) from public,anon;
grant execute on function public.admin_grant_creator_access(uuid) to authenticated;

-- Keep all interview, assessment and recording endpoints restricted to partner applications.
do $$
declare v text;
begin
 select pg_get_functiondef('public.can_access_academy_interview(uuid)'::regprocedure) into v;
 v:=replace(v,'where i.id=p_interview_id' || E'\n      and (public.is_admin()',
  'where i.id=p_interview_id and a.application_type in (''creator'',''instructor'',''teacher'',''exhibitor'')' || E'\n      and (public.is_admin()');
 execute v;

 select pg_get_functiondef('public.can_upload_academy_interview(uuid)'::regprocedure) into v;
 v:=replace(v,'where i.id=p_interview_id and a.user_id=auth.uid()',
  'where i.id=p_interview_id and a.application_type in (''creator'',''instructor'',''teacher'',''exhibitor'') and a.user_id=auth.uid()');
 execute v;

 select pg_get_functiondef('public.get_my_academy_interview_assignments()'::regprocedure) into v;
 v:=replace(v,'where i.reviewer_id=auth.uid() or public.is_admin()',
  'where (i.reviewer_id=auth.uid() or public.is_admin()) and a.application_type in (''creator'',''instructor'',''teacher'',''exhibitor'')');
 execute v;

 select pg_get_functiondef('public.get_my_academy_interview_details(uuid)'::regprocedure) into v;
 v:=replace(v,'if not found or a.user_id is distinct from auth.uid() then',
  'if not found or a.user_id is distinct from auth.uid() or a.application_type not in (''creator'',''instructor'',''teacher'',''exhibitor'') then');
 execute v;

 select pg_get_functiondef('public.respond_to_academy_interview_invitation(uuid,text)'::regprocedure) into v;
 v:=replace(v,'if not found then raise exception ''Interview invitation not found''; end if;',
  'if not found then raise exception ''Interview invitation not found''; end if;' || E'\n if not exists(select 1 from public.academy_applications a where a.id=v_inv.application_id and a.application_type in (''creator'',''instructor'',''teacher'',''exhibitor'')) then raise exception ''Interview invitations are reserved for CreatorVerse partner applicants''; end if;');
 execute v;

 select pg_get_functiondef('public.ring_academy_live_interview(uuid)'::regprocedure) into v;
 v:=replace(v,'if not found then raise exception ''Applicant record not found''; end if;',
  'if not found then raise exception ''Applicant record not found''; end if;' || E'\n if a.application_type not in (''creator'',''instructor'',''teacher'',''exhibitor'') then raise exception ''Live interviews are reserved for CreatorVerse partner applicants''; end if;');
 execute v;

 select pg_get_functiondef('public.submit_academy_interview_response(uuid,text,integer,boolean)'::regprocedure) into v;
 v:=replace(v,'if not found or v_app.user_id is distinct from auth.uid() then raise exception ''This interview is not assigned to your account''; end if;',
  'if not found or v_app.user_id is distinct from auth.uid() or v_app.application_type not in (''creator'',''instructor'',''teacher'',''exhibitor'') then raise exception ''This creator assessment is not assigned to your account''; end if;');
 execute v;
end $$;

notify pgrst,'reload schema';
