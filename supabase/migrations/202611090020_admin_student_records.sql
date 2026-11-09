create or replace function public.admin_get_student_record(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if p_user_id is null then
    raise exception 'Student id is required' using errcode = '22004';
  end if;

  select jsonb_build_object(
    'profile', (
      select jsonb_build_object(
        'id', p.id, 'full_name', p.full_name, 'email', p.email,
        'role', p.role, 'created_at', p.created_at, 'avatar_url', p.avatar_url,
        'username', p.username, 'bio', p.bio, 'location', p.location,
        'website_url', p.website_url, 'status_text', p.status_text,
        'verified_badge', p.verified_badge
      ) from public.profiles p where p.id = p_user_id and p.role = 'student'
    ),
    'applications', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', a.id, 'application_no', a.application_no, 'course_title', c.title,
        'status', a.status, 'submitted_at', a.submitted_at, 'reviewed_at', a.reviewed_at,
        'education_level', a.education_level, 'occupation', a.occupation,
        'prior_experience', a.prior_experience, 'portfolio_url', a.portfolio_url,
        'motivation', a.motivation, 'learning_goals', a.learning_goals,
        'decision_reason', a.decision_reason, 'admission_cohort', a.admission_cohort,
        'offer_issued_at', a.offer_issued_at, 'offer_expires_at', a.offer_expires_at,
        'offer_accepted_at', a.offer_accepted_at
      ) order by a.submitted_at desc)
      from public.academy_applications a
      left join public.courses c on c.id = a.course_id
      where a.user_id = p_user_id
    ), '[]'::jsonb),
    'courses', coalesce((
      select jsonb_agg(x order by (x->>'last_activity') desc nulls last)
      from jsonb_array_elements(public.admin_get_student_performance(500)) x
      where x->>'user_id' = p_user_id::text
    ), '[]'::jsonb),
    'levels', coalesce((
      select jsonb_agg(jsonb_build_object(
        'course_title', c.title, 'current_level', l.current_level,
        'highest_unlocked_level', l.highest_unlocked_level,
        'progress_percent', l.progress_percent, 'completed_lessons', l.completed_lessons,
        'total_lessons', l.total_lessons, 'last_activity_at', l.last_activity_at,
        'admin_override', l.admin_override, 'admin_note', l.admin_note
      ) order by c.title)
      from public.academy_learner_levels l
      join public.courses c on c.id = l.course_id
      where l.user_id = p_user_id
    ), '[]'::jsonb),
    'level_requests', coalesce((
      select jsonb_agg(jsonb_build_object(
        'course_title', c.title, 'level_name', r.level_name, 'status', r.status,
        'progress_percent', r.progress_percent, 'requested_at', r.requested_at,
        'reviewed_at', r.reviewed_at, 'reviewer_note', r.reviewer_note
      ) order by r.requested_at desc)
      from public.academy_level_unlock_requests r
      join public.courses c on c.id = r.course_id
      where r.user_id = p_user_id
    ), '[]'::jsonb),
    'submissions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'assignment_title', a.title, 'course_title', c.title,
        'status', s.status, 'grade', s.grade, 'feedback', s.feedback,
        'submitted_at', s.submitted_at, 'graded_at', s.graded_at
      ) order by s.submitted_at desc)
      from public.submissions s
      join public.assignments a on a.id = s.assignment_id
      join public.courses c on c.id = a.course_id
      where s.user_id = p_user_id
    ), '[]'::jsonb),
    'recent_activity', coalesce((
      select jsonb_agg(jsonb_build_object(
        'activity_type', la.activity_type, 'course_title', c.title,
        'occurred_at', la.occurred_at, 'metadata', la.metadata
      ) order by la.occurred_at desc)
      from (
        select * from public.academy_learning_activity
        where user_id = p_user_id
        order by occurred_at desc limit 30
      ) la
      left join public.courses c on c.id = la.course_id
    ), '[]'::jsonb)
  ) into result;

  if result->'profile' is null then
    raise exception 'Student account not found' using errcode = 'P0002';
  end if;
  return result;
end;
$function$;

revoke all on function public.admin_get_student_record(uuid) from public, anon;
grant execute on function public.admin_get_student_record(uuid) to authenticated;