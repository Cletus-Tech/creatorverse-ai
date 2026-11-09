-- Student-facing engagement report and deduplicated learning reminders.
create table if not exists public.academy_engagement_alert_state (
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  last_status text not null check (last_status in ('on_track','below_target','inactive','not_started')),
  last_notified_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key(user_id,course_id)
);
alter table public.academy_engagement_alert_state enable row level security;
revoke all on public.academy_engagement_alert_state from public,anon,authenticated;
grant all on public.academy_engagement_alert_state to service_role;

create or replace function public.student_get_my_engagement()
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
  v_uid uuid:=auth.uid(); v_row record; v_status text; v_previous text;
  v_last_notified timestamptz; v_should_notify boolean;
  v_courses jsonb:='[]'::jsonb; v_count integer:=0;
begin
  if v_uid is null then raise exception 'Please sign in to view your learning engagement.'; end if;
  if not exists(select 1 from public.profiles p where p.id=v_uid and p.role='student') then
    raise exception 'Student access is required.';
  end if;
  for v_row in
    select e.course_id,c.slug as course_slug,c.title as course_title,
      coalesce(pol.min_events_per_week,2) as min_events_per_week,
      coalesce(pol.inactivity_days,14) as inactivity_days,
      greatest(la.last_activity,lp.last_completed_at) as last_activity,
      coalesce(la.events_7d,0)::integer as events_7d,
      coalesce(la.views_7d,0)::integer as lesson_views_7d,
      coalesce(lp.completed_count,0)::integer as lessons_completed,
      coalesce(lt.total_count,0)::integer as total_lessons
    from public.enrolments e
    join public.courses c on c.id=e.course_id
    left join public.academy_engagement_policies pol on pol.course_id=e.course_id
    left join lateral (
      select max(a.occurred_at) as last_activity,
        count(*) filter(where a.occurred_at>=now()-interval '7 days') as events_7d,
        count(*) filter(where a.activity_type='lesson_viewed' and a.occurred_at>=now()-interval '7 days') as views_7d
      from public.academy_learning_activity a where a.user_id=e.user_id and a.course_id=e.course_id
    ) la on true
    left join lateral (
      select count(*) filter(where x.completed_at is not null) as completed_count,max(x.completed_at) as last_completed_at
      from public.lesson_progress x
      join public.lessons l on l.id=x.lesson_id
      join public.modules m on m.id=l.module_id
      where x.user_id=e.user_id and m.course_id=e.course_id
    ) lp on true
    left join lateral (
      select count(*) as total_count from public.lessons l
      join public.modules m on m.id=l.module_id where m.course_id=e.course_id
    ) lt on true
    where e.user_id=v_uid order by c.title
  loop
    v_count:=v_count+1;
    if v_row.last_activity is null then v_status:='not_started';
    elsif v_row.last_activity<now()-make_interval(days=>v_row.inactivity_days) then v_status:='inactive';
    elsif v_row.events_7d<v_row.min_events_per_week then v_status:='below_target';
    else v_status:='on_track'; end if;

    select s.last_status,s.last_notified_at into v_previous,v_last_notified
    from public.academy_engagement_alert_state s
    where s.user_id=v_uid and s.course_id=v_row.course_id;

    v_should_notify:=v_status<>'on_track' and
      (v_previous is distinct from v_status or v_last_notified is null or v_last_notified<now()-interval '7 days');

    if v_should_notify then
      insert into public.cv_notifications(user_id,type,title,body,href,entity_type,entity_id)
      values(v_uid,'academy_engagement',
        case v_status when 'inactive' then 'Your course needs your attention'
          when 'below_target' then 'Your weekly learning target needs attention'
          else 'Start your learning journey' end,
        case v_status
          when 'inactive' then 'You have not recorded learning activity in this course for a while. Open your course and continue with your next lesson.'
          when 'below_target' then 'You have recorded '||v_row.events_7d||' learning activities in the last 7 days. Your current weekly target is '||v_row.min_events_per_week||'. Take a little time to continue learning.'
          else 'You are enrolled in this course but have no recorded lesson activity yet. Start your first lesson to begin tracking your progress.' end,
        'dashboard.html#engagement','course',v_row.course_id);
    end if;

    insert into public.academy_engagement_alert_state(user_id,course_id,last_status,last_notified_at,updated_at)
    values(v_uid,v_row.course_id,v_status,case when v_should_notify then now() else v_last_notified end,now())
    on conflict(user_id,course_id) do update set last_status=excluded.last_status,
      last_notified_at=case when v_should_notify then now() else public.academy_engagement_alert_state.last_notified_at end,
      updated_at=now();

    v_courses:=v_courses||jsonb_build_array(jsonb_build_object(
      'course_id',v_row.course_id,'course_slug',v_row.course_slug,'course_title',v_row.course_title,
      'min_events_per_week',v_row.min_events_per_week,'inactivity_days',v_row.inactivity_days,
      'last_activity',v_row.last_activity,'events_7d',v_row.events_7d,'lesson_views_7d',v_row.lesson_views_7d,
      'lessons_completed',v_row.lessons_completed,'total_lessons',v_row.total_lessons,'status',v_status));
  end loop;
  return jsonb_build_object('generated_at',now(),'enrolled_courses',v_count,'courses',v_courses);
end $$;
revoke all on function public.student_get_my_engagement() from public,anon;
grant execute on function public.student_get_my_engagement() to authenticated;