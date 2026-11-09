-- Expand Academy analytics to include recorded lesson views and learning activity.
-- Admin-only aggregate RPCs; no student-facing data access is granted.

create or replace function public.admin_get_academy_analytics()
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'generated_at', now(),
    'students', (select count(*) from public.profiles p where p.role = 'student'),
    'enrolments', (select count(*) from public.enrolments),
    'active_7d', (select count(distinct x.user_id) from (
      select a.user_id from public.academy_learning_activity a where a.occurred_at >= now()-interval '7 days'
      union select lp.user_id from public.lesson_progress lp where lp.completed_at >= now()-interval '7 days'
      union select qa.user_id from public.quiz_attempts qa where qa.created_at >= now()-interval '7 days'
      union select s.user_id from public.submissions s where coalesce(s.graded_at,s.submitted_at) >= now()-interval '7 days'
    ) x),
    'inactive_14d', (select count(*) from public.enrolments e
      where not exists (select 1 from public.academy_learning_activity a where a.user_id=e.user_id and a.course_id=e.course_id and a.occurred_at >= now()-interval '14 days')
      and not exists (select 1 from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where m.course_id=e.course_id and lp.user_id=e.user_id and lp.completed_at >= now()-interval '14 days')
      and not exists (select 1 from public.quiz_attempts qa join public.quizzes q on q.id=qa.quiz_id where q.course_id=e.course_id and qa.user_id=e.user_id and qa.created_at >= now()-interval '14 days')
      and not exists (select 1 from public.submissions s join public.assignments a on a.id=s.assignment_id where a.course_id=e.course_id and s.user_id=e.user_id and coalesce(s.graded_at,s.submitted_at) >= now()-interval '14 days')),
    'applications_pending', (select count(*) from public.academy_applications a where a.status in ('submitted','pending','under_review','interview_scheduled')),
    'applications_approved', (select count(*) from public.academy_applications a where a.status in ('approved','approved_pending_payment')),
    'certificates_issued', (select count(*) from public.certificates c where coalesce(c.revoked,false)=false),
    'lessons_completed_30d', (select count(*) from public.lesson_progress lp where lp.completed_at >= now()-interval '30 days'),
    'lesson_views_30d', (select count(*) from public.academy_learning_activity a where a.activity_type='lesson_viewed' and a.occurred_at >= now()-interval '30 days'),
    'learning_events_30d', (select count(*) from public.academy_learning_activity a where a.occurred_at >= now()-interval '30 days'),
    'pending_assignment_reviews', (select count(*) from public.submissions s where s.status='submitted' and s.graded_at is null),
    'course_performance', coalesce((select jsonb_agg(z order by z.enrolments desc) from (
      select c.id,c.title,
        (select count(*) from public.enrolments e where e.course_id=c.id) enrolments,
        (select count(*) from public.modules m join public.lessons l on l.module_id=m.id where m.course_id=c.id) total_lessons,
        (select count(*) from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where m.course_id=c.id) completed_lessons,
        (select count(*) from public.quizzes q where q.course_id=c.id) quizzes,
        (select count(*) from public.assignments a where a.course_id=c.id) assignments,
        (select count(distinct e.user_id) from public.enrolments e where e.course_id=c.id and (
          exists(select 1 from public.academy_learning_activity la where la.user_id=e.user_id and la.course_id=e.course_id and la.occurred_at >= now()-interval '7 days')
          or exists(select 1 from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where m.course_id=e.course_id and lp.user_id=e.user_id and lp.completed_at >= now()-interval '7 days')
        )) active_learners_7d
      from public.courses c where c.published=true
    ) z), '[]'::jsonb)
  ) into result;
  return result;
end;
$function$;

create or replace function public.admin_get_student_performance(p_limit integer default 200)
returns jsonb language plpgsql security definer set search_path = ''
as $function$
declare result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  with enrolled as (
    select e.user_id,e.course_id,e.created_at enrolment_date,p.full_name,p.email,c.title course_title,c.id course_id_ref
    from public.enrolments e join public.profiles p on p.id=e.user_id join public.courses c on c.id=e.course_id
    where p.role='student'
  ), stats as (
    select en.*,
      (select count(*) from public.lessons l join public.modules m on m.id=l.module_id where m.course_id=en.course_id) total_lessons,
      (select count(*) from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where m.course_id=en.course_id and lp.user_id=en.user_id) completed_lessons,
      (select count(*) from public.quizzes q where q.course_id=en.course_id) total_quizzes,
      (select count(distinct qa.quiz_id) from public.quiz_attempts qa join public.quizzes q on q.id=qa.quiz_id where q.course_id=en.course_id and qa.user_id=en.user_id and qa.passed=true) passed_quizzes,
      (select round(avg(qa.score)::numeric,1) from public.quiz_attempts qa join public.quizzes q on q.id=qa.quiz_id where q.course_id=en.course_id and qa.user_id=en.user_id) average_quiz_score,
      (select count(*) from public.assignments a where a.course_id=en.course_id) total_assignments,
      (select count(*) from public.submissions s join public.assignments a on a.id=s.assignment_id where a.course_id=en.course_id and s.user_id=en.user_id) submitted_assignments,
      (select count(*) from public.submissions s join public.assignments a on a.id=s.assignment_id where a.course_id=en.course_id and s.user_id=en.user_id and s.graded_at is not null) graded_assignments,
      (select count(*) from public.academy_learning_activity la where la.user_id=en.user_id and la.course_id=en.course_id and la.activity_type='lesson_viewed') lesson_views,
      greatest(en.enrolment_date,
        coalesce((select max(la.occurred_at) from public.academy_learning_activity la where la.course_id=en.course_id and la.user_id=en.user_id), en.enrolment_date),
        coalesce((select max(lp.completed_at) from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where m.course_id=en.course_id and lp.user_id=en.user_id), en.enrolment_date),
        coalesce((select max(qa.created_at) from public.quiz_attempts qa join public.quizzes q on q.id=qa.quiz_id where q.course_id=en.course_id and qa.user_id=en.user_id), en.enrolment_date),
        coalesce((select max(s.graded_at) from public.submissions s join public.assignments a on a.id=s.assignment_id where a.course_id=en.course_id and s.user_id=en.user_id), en.enrolment_date),
        coalesce((select max(s.submitted_at) from public.submissions s join public.assignments a on a.id=s.assignment_id where a.course_id=en.course_id and s.user_id=en.user_id), en.enrolment_date)
      ) last_activity
    from enrolled en
  )
  select coalesce(jsonb_agg(to_jsonb(x) order by x.last_activity desc), '[]'::jsonb) into result
  from (
    select s.*,
      (s.total_lessons>0 and s.completed_lessons>=s.total_lessons and s.passed_quizzes>=s.total_quizzes and s.graded_assignments>=s.total_assignments) certificate_review_ready,
      (s.last_activity < now()-interval '14 days') inactive_14d,
      case when s.total_lessons>0 then round(100.0*s.completed_lessons/s.total_lessons,1) else 0 end completion_percent
    from stats s order by s.last_activity desc limit greatest(1,least(coalesce(p_limit,200),500))
  ) x;
  return result;
end;
$function$;

revoke all on function public.admin_get_academy_analytics() from public, anon;
grant execute on function public.admin_get_academy_analytics() to authenticated;
revoke all on function public.admin_get_student_performance(integer) from public, anon;
grant execute on function public.admin_get_student_performance(integer) to authenticated;