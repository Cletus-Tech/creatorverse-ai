-- Reviewer workspace data and authenticated private WebRTC signalling access.
create or replace function public.get_my_academy_interview_assignments()
returns table(
  interview_id uuid, application_id uuid, application_no text, applicant_name text,
  course_title text, interview_type text, interview_status text, topic text,
  instructions text, scheduled_start timestamptz, scheduled_end timestamptz,
  timezone text, preparation_seconds integer, max_duration_seconds integer,
  assessment_criteria jsonb, round_number integer, score numeric,
  reviewer_notes text, media_object_path text, invitation_id uuid,
  invitation_status text, starts_at timestamptz, ends_at timestamptz
)
language plpgsql stable security definer set search_path = pg_catalog, public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  return query
  select i.id, i.application_id, a.application_no,
    concat_ws(' ', a.first_name, nullif(a.middle_name,''), a.last_name),
    c.title, i.interview_type, i.status, i.topic, i.instructions,
    i.scheduled_start, i.scheduled_end, i.timezone, i.preparation_seconds,
    i.max_duration_seconds, i.assessment_criteria, i.round_number, i.score,
    i.reviewer_notes, i.media_object_path, inv.id, inv.status, inv.starts_at, inv.ends_at
  from public.academy_interviews i
  join public.academy_applications a on a.id=i.application_id
  left join public.courses c on c.id=a.course_id
  left join lateral (
    select v.* from public.academy_interview_invitations v
    where v.interview_id=i.id order by v.created_at desc limit 1
  ) inv on true
  where i.reviewer_id=auth.uid() or public.is_admin()
  order by coalesce(i.scheduled_start,i.created_at) desc;
end
$$;
revoke all on function public.get_my_academy_interview_assignments() from public, anon;
grant execute on function public.get_my_academy_interview_assignments() to authenticated;

create or replace function public.can_access_academy_interview(p_interview_id uuid)
returns boolean
language sql stable security definer set search_path = pg_catalog, public
as $$
  select auth.uid() is not null and exists (
    select 1 from public.academy_interviews i
    join public.academy_applications a on a.id=i.application_id
    where i.id=p_interview_id
      and (public.is_admin() or i.reviewer_id=auth.uid() or a.user_id=auth.uid())
  )
$$;
revoke all on function public.can_access_academy_interview(uuid) from public, anon;
grant execute on function public.can_access_academy_interview(uuid) to authenticated;

drop policy if exists "Academy interview participants receive private signals" on realtime.messages;
create policy "Academy interview participants receive private signals"
on realtime.messages for select to authenticated
using (
  realtime.topic() ~ '^academy-interview:[0-9a-fA-F-]{36}$'
  and public.can_access_academy_interview(split_part(realtime.topic(),':',2)::uuid)
);

drop policy if exists "Academy interview participants send private signals" on realtime.messages;
create policy "Academy interview participants send private signals"
on realtime.messages for insert to authenticated
with check (
  realtime.topic() ~ '^academy-interview:[0-9a-fA-F-]{36}$'
  and public.can_access_academy_interview(split_part(realtime.topic(),':',2)::uuid)
);
