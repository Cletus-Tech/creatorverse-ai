-- Keep reviewer-only evaluation fields private: applicants receive only a safe
-- interview brief through a narrowly scoped RPC, never the full interview row.
drop policy if exists "Applicants read own published interview details" on public.academy_interviews;

create or replace function public.get_my_academy_interview_details(p_interview_id uuid)
returns jsonb language plpgsql stable security definer set search_path = pg_catalog, public
as $$
declare v public.academy_interviews%rowtype; a public.academy_applications%rowtype;
        inv public.academy_interview_invitations%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into v from public.academy_interviews where id=p_interview_id;
  if not found then raise exception 'Interview not found'; end if;
  select * into a from public.academy_applications where id=v.application_id;
  if not found or a.user_id is distinct from auth.uid() then raise exception 'This interview is not assigned to your account'; end if;
  select * into inv from public.academy_interview_invitations
    where interview_id=p_interview_id and user_id=auth.uid() and published_at is not null
    order by created_at desc limit 1;
  if not found then raise exception 'Published interview invitation not found'; end if;
  return jsonb_build_object(
    'interview',jsonb_build_object(
      'id',v.id,'interview_type',v.interview_type,'status',v.status,'topic',v.topic,
      'instructions',v.instructions,'preparation_seconds',v.preparation_seconds,
      'max_duration_seconds',v.max_duration_seconds,'assessment_criteria',v.assessment_criteria,
      'round_number',v.round_number,'scheduled_start',v.scheduled_start,
      'scheduled_end',v.scheduled_end,'timezone',v.timezone,'reviewer_id',v.reviewer_id
    ),
    'invitation',jsonb_build_object(
      'id',inv.id,'status',inv.status,'starts_at',inv.starts_at,'ends_at',inv.ends_at,
      'timezone',inv.timezone,'learner_instructions',inv.learner_instructions
    )
  );
end
$$;
revoke all on function public.get_my_academy_interview_details(uuid) from public, anon;
grant execute on function public.get_my_academy_interview_details(uuid) to authenticated;

create or replace function public.can_upload_academy_interview(p_interview_id uuid)
returns boolean language sql stable security definer set search_path = pg_catalog, public
as $$
  select auth.uid() is not null and exists (
    select 1 from public.academy_interviews i
    join public.academy_applications a on a.id=i.application_id
    join public.academy_interview_invitations inv on inv.interview_id=i.id
    where i.id=p_interview_id and a.user_id=auth.uid() and inv.user_id=auth.uid()
      and inv.published_at is not null and inv.starts_at<=now() and inv.ends_at>=now()
      and i.interview_type in ('recorded_audio','recorded_video')
      and i.status in ('pending','scheduled','in_progress')
  )
$$;
revoke all on function public.can_upload_academy_interview(uuid) from public, anon;
grant execute on function public.can_upload_academy_interview(uuid) to authenticated;

drop policy if exists "Academy interview participants upload own media" on storage.objects;
create policy "Academy interview participants upload own media"
on storage.objects for insert to authenticated
with check (
  bucket_id='academy-interviews'
  and (storage.foldername(name))[2]=auth.uid()::text
  and public.can_upload_academy_interview(((storage.foldername(name))[1])::uuid)
);

drop policy if exists "Academy interview participants read private media" on storage.objects;
create policy "Academy assigned reviewers and admins read private media"
on storage.objects for select to authenticated
using (
  bucket_id='academy-interviews'
  and exists (
    select 1 from public.academy_interviews i
    where i.id::text=(storage.foldername(name))[1]
      and (i.reviewer_id=auth.uid() or public.is_admin())
  )
);

drop policy if exists "Academy interview owners update own media" on storage.objects;
