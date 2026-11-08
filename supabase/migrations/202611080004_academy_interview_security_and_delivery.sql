-- Academy interview delivery foundation: internal interview configuration,
-- applicant/reviewer visibility, private media storage and secure reviewer scoring.
alter table public.academy_interviews
  add column if not exists topic text,
  add column if not exists instructions text,
  add column if not exists preparation_seconds integer not null default 0,
  add column if not exists max_duration_seconds integer not null default 600,
  add column if not exists assessment_criteria jsonb not null default '[]'::jsonb,
  add column if not exists round_number integer not null default 1,
  add column if not exists consent_required boolean not null default true;

alter table public.academy_interview_invitations
  add column if not exists response_due_at timestamptz,
  add column if not exists applicant_submitted_at timestamptz;

alter table public.academy_interviews
  drop constraint if exists academy_interviews_preparation_seconds_check,
  add constraint academy_interviews_preparation_seconds_check check (preparation_seconds between 0 and 3600),
  drop constraint if exists academy_interviews_max_duration_seconds_check,
  add constraint academy_interviews_max_duration_seconds_check check (max_duration_seconds between 30 and 7200),
  drop constraint if exists academy_interviews_round_number_check,
  add constraint academy_interviews_round_number_check check (round_number between 1 and 20);

-- Applicants can read only the interview attached to their own published invitation.
drop policy if exists "Applicants read own published interview details" on public.academy_interviews;
create policy "Applicants read own published interview details"
on public.academy_interviews for select to authenticated
using (
  exists (
    select 1 from public.academy_interview_invitations inv
    join public.academy_applications app on app.id = inv.application_id
    where inv.interview_id = academy_interviews.id
      and inv.user_id = auth.uid()
      and inv.published_at is not null
      and app.user_id = auth.uid()
  )
);

-- Assigned interviewers can see only interviews explicitly assigned to them.
drop policy if exists "Assigned reviewers read their interviews" on public.academy_interviews;
create policy "Assigned reviewers read their interviews"
on public.academy_interviews for select to authenticated
using (reviewer_id = auth.uid());

-- Assigned reviewers can see the invitation schedule/instructions for their own cases.
drop policy if exists "Assigned reviewers read their invitations" on public.academy_interview_invitations;
create policy "Assigned reviewers read their invitations"
on public.academy_interview_invitations for select to authenticated
using (
  exists (
    select 1 from public.academy_interviews i
    where i.id = academy_interview_invitations.interview_id
      and i.reviewer_id = auth.uid()
  )
);

create or replace function public.submit_academy_interview_review(
  p_interview_id uuid,
  p_score numeric,
  p_reviewer_notes text,
  p_completed boolean default true
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare v_interview public.academy_interviews%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into v_interview from public.academy_interviews where id = p_interview_id for update;
  if not found then raise exception 'Interview not found'; end if;
  if not public.is_admin() and v_interview.reviewer_id is distinct from auth.uid() then
    raise exception 'You are not assigned to review this interview';
  end if;
  if p_score is not null and (p_score < 0 or p_score > 100) then
    raise exception 'Score must be between 0 and 100';
  end if;
  update public.academy_interviews
  set score = p_score,
      reviewer_notes = nullif(btrim(p_reviewer_notes), ''),
      status = case when p_completed then 'completed' else 'submitted' end,
      updated_at = now()
  where id = p_interview_id;
  return jsonb_build_object('success', true, 'status', case when p_completed then 'completed' else 'submitted' end);
end
$$;
revoke all on function public.submit_academy_interview_review(uuid,numeric,text,boolean) from public, anon;
grant execute on function public.submit_academy_interview_review(uuid,numeric,text,boolean) to authenticated;

-- Keep interview media private and restrict it to applicant, assigned reviewer and admins.
update storage.buckets
set public = false,
    file_size_limit = 104857600,
    allowed_mime_types = array['audio/webm','audio/mp4','audio/mpeg','video/webm','video/mp4','video/quicktime']
where id = 'academy-interviews';

drop policy if exists "Academy interview participants upload own media" on storage.objects;
create policy "Academy interview participants upload own media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'academy-interviews'
  and exists (
    select 1 from public.academy_interviews i
    join public.academy_interview_invitations inv on inv.interview_id = i.id
    join public.academy_applications app on app.id = i.application_id
    where i.id::text = (storage.foldername(name))[1]
      and app.user_id = auth.uid()
      and inv.user_id = auth.uid()
      and inv.published_at is not null
      and i.interview_type in ('recorded_audio','recorded_video')
      and i.status in ('pending','scheduled','in_progress')
      and (storage.foldername(name))[2] = auth.uid()::text
  )
);

drop policy if exists "Academy interview participants read private media" on storage.objects;
create policy "Academy interview participants read private media"
on storage.objects for select to authenticated
using (
  bucket_id = 'academy-interviews'
  and exists (
    select 1 from public.academy_interviews i
    join public.academy_applications app on app.id = i.application_id
    where i.id::text = (storage.foldername(name))[1]
      and (app.user_id = auth.uid() or i.reviewer_id = auth.uid() or public.is_admin())
  )
);

drop policy if exists "Academy interview owners update own media" on storage.objects;
create policy "Academy interview owners update own media"
on storage.objects for update to authenticated
using (
  bucket_id = 'academy-interviews'
  and exists (
    select 1 from public.academy_interviews i
    join public.academy_applications app on app.id = i.application_id
    where i.id::text = (storage.foldername(name))[1]
      and app.user_id = auth.uid()
  )
)
with check (
  bucket_id = 'academy-interviews'
  and exists (
    select 1 from public.academy_interviews i
    join public.academy_applications app on app.id = i.application_id
    where i.id::text = (storage.foldername(name))[1]
      and app.user_id = auth.uid()
  )
);

drop policy if exists "Academy admins delete interview media" on storage.objects;
create policy "Academy admins delete interview media"
on storage.objects for delete to authenticated
using (bucket_id = 'academy-interviews' and public.is_admin());
