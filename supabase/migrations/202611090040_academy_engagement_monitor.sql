create table if not exists public.academy_engagement_policies (
  course_id uuid primary key references public.courses(id) on delete cascade,
  min_events_per_week integer not null default 2 check (min_events_per_week between 0 and 50),
  inactivity_days integer not null default 14 check (inactivity_days between 1 and 90),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);
alter table public.academy_engagement_policies enable row level security;
revoke all on public.academy_engagement_policies from anon, authenticated;
grant all on public.academy_engagement_policies to service_role;

create or replace function public.admin_set_course_engagement_policy(
  p_course_id uuid, p_min_events_per_week integer, p_inactivity_days integer
) returns jsonb
language plpgsql security definer set search_path=public
as $$
declare v_row public.academy_engagement_policies;
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required.'; end if;
  if p_min_events_per_week not between 0 and 50 or p_inactivity_days not between 1 and 90 then
    raise exception 'Weekly activity target must be 0–50 and inactivity threshold 1–90 days.';
  end if;
  if not exists(select 1 from public.courses where id=p_course_id) then raise exception 'Course not found.'; end if;
  insert into public.academy_engagement_policies(course_id,min_events_per_week,inactivity_days,updated_by,updated_at)
  values(p_course_id,p_min_events_per_week,p_inactivity_days,auth.uid(),now())
  on conflict(course_id) do update set min_events_per_week=excluded.min_events_per_week,
    inactivity_days=excluded.inactivity_days,updated_by=excluded.updated_by,updated_at=now()
  returning * into v_row;
  return jsonb_build_object('course_id',v_row.course_id,'min_events_per_week',v_row.min_events_per_week,'inactivity_days',v_row.inactivity_days,'updated_at',v_row.updated_at);
end $$;

create or replace function public.admin_get_engagement_overview()
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required.'; end if;
  select jsonb_build_object(
    'generated_at',now(),
    'courses',coalesce((
      select jsonb_agg(jsonb_build_object(
        'course_id',c.id,'course_title',c.title,'published',c.published,
        'min_events_per_week',coalesce(pol.min_events_per_week,2),
        'inactivity_days',coalesce(pol.inactivity_days,14),
        'updated_at',pol.updated_at,
        'learners',coalesce((
          select jsonb_agg(jsonb_build_object(
            'student_id',p.id,'full_name',coalesce(p.full_name,p.email,'Student'),'email',p.email,
            'last_activity',la.last_activity,'events_7d',coalesce(la.events_7d,0),
            'lesson_views_7d',coalesce(la.views_7d,0),'lessons_completed',coalesce(lp.completed_count,0),
            'total_lessons',coalesce(lt.total_count,0),
            'status',case
              when la.last_activity is null then 'not_started'
              when la.last_activity < now()-make_interval(days=>coalesce(pol.inactivity_days,14)) then 'inactive'
              when coalesce(la.events_7d,0)<coalesce(pol.min_events_per_week,2) then 'below_target'
              else 'on_track' end
          ) order by la.last_activity asc nulls first,p.full_name)
          from public.enrolments e
          join public.profiles p on p.id=e.user_id and p.role='student'
          left join lateral (
            select max(a.occurred_at) last_activity,
              count(*) filter(where a.occurred_at>=now()-interval '7 days')::integer events_7d,
              count(*) filter(where a.activity_type='lesson_viewed' and a.occurred_at>=now()-interval '7 days')::integer views_7d
            from public.academy_learning_activity a where a.user_id=e.user_id and a.course_id=e.course_id
          ) la on true
          left join lateral (
            select count(*)::integer completed_count from public.lesson_progress x
            join public.lessons l on l.id=x.lesson_id
            join public.modules m on m.id=l.module_id
            where x.user_id=e.user_id and m.course_id=e.course_id and x.completed_at is not null
          ) lp on true
          left join lateral (
            select count(*)::integer total_count from public.lessons l
            join public.modules m on m.id=l.module_id where m.course_id=e.course_id
          ) lt on true
          where e.course_id=c.id
        ),'[]'::jsonb)
      ) order by c.title)
      from public.courses c
      left join public.academy_engagement_policies pol on pol.course_id=c.id
    ),'[]'::jsonb)
  ) into v_result;
  return v_result;
end $$;

revoke all on function public.admin_set_course_engagement_policy(uuid,integer,integer) from public, anon;
revoke all on function public.admin_get_engagement_overview() from public, anon;
grant execute on function public.admin_set_course_engagement_policy(uuid,integer,integer) to authenticated;
grant execute on function public.admin_get_engagement_overview() to authenticated;