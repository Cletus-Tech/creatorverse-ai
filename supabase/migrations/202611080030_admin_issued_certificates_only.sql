-- CreatorVerse Academy: certificates are reviewed and issued by administrators only.
-- Learners may track completion, but cannot self-issue, print or download certificates.

create or replace function public.claim_certificate(p_course uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
begin
  raise exception 'Certificates are issued by CreatorVerse Academy administrators after review. Please contact the Academy team.';
end $$;
revoke all on function public.claim_certificate(uuid) from public, anon, authenticated;

create or replace function public.admin_issue_certificate(p_user_id uuid,p_course_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_course record;
  v_name text;
  v_total integer;
  v_done integer;
  v_quizzes integer;
  v_passed integer;
  v_assignments integer;
  v_graded integer;
  v_no text;
  v_existing record;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Only Academy administrators can issue certificates';
  end if;
  if p_user_id is null or p_course_id is null then raise exception 'Select a student and course'; end if;
  select id,title,published into v_course from public.courses where id=p_course_id;
  if not found or not v_course.published then raise exception 'Course is not available'; end if;
  if not exists(select 1 from public.enrolments where user_id=p_user_id and course_id=p_course_id) then
    raise exception 'Student is not enrolled in this course';
  end if;
  select * into v_existing from public.certificates where user_id=p_user_id and course_id=p_course_id;
  if found then return jsonb_build_object('certificate_no',v_existing.certificate_no,'already_issued',true); end if;
  select count(*) into v_total from public.lessons l join public.modules m on m.id=l.module_id where m.course_id=p_course_id;
  select count(*) into v_done from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where m.course_id=p_course_id and lp.user_id=p_user_id and lp.completed_at is not null;
  if v_total=0 or v_done<v_total then raise exception 'Student has not completed every lesson'; end if;
  select count(*) into v_quizzes from public.quizzes where course_id=p_course_id;
  select count(*) into v_passed from public.quizzes q where q.course_id=p_course_id and exists(select 1 from public.quiz_attempts a where a.quiz_id=q.id and a.user_id=p_user_id and a.passed);
  if v_passed<v_quizzes then raise exception 'Student must pass every published quiz'; end if;
  select count(*) into v_assignments from public.assignments where course_id=p_course_id;
  select count(*) into v_graded from public.assignments a where a.course_id=p_course_id and exists(select 1 from public.submissions s where s.assignment_id=a.id and s.user_id=p_user_id and s.status='graded');
  if v_graded<v_assignments then raise exception 'All student assignments must be graded first'; end if;
  select coalesce(nullif(full_name,''),'Student') into v_name from public.profiles where id=p_user_id;
  v_no:='CV-'||to_char(now(),'YYYY')||'-'||upper(substr(md5(random()::text||clock_timestamp()::text),1,8));
  insert into public.certificates(user_id,course_id,certificate_no,student_name,course_title)
  values(p_user_id,p_course_id,v_no,coalesce(v_name,'Student'),v_course.title);
  return jsonb_build_object('certificate_no',v_no,'already_issued',false);
end $$;
revoke all on function public.admin_issue_certificate(uuid,uuid) from public,anon;
grant execute on function public.admin_issue_certificate(uuid,uuid) to authenticated;
