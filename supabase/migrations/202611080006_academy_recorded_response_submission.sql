-- Secure submission endpoint for recorded audio/video defence responses.
create or replace function public.submit_academy_interview_response(
  p_interview_id uuid,
  p_media_path text,
  p_duration_seconds integer,
  p_consent boolean
) returns jsonb
language plpgsql security definer set search_path = pg_catalog, public
as $$
declare v_interview public.academy_interviews%rowtype; v_app public.academy_applications%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_consent is distinct from true then raise exception 'Consent is required before submitting a recording'; end if;
  if p_duration_seconds is null or p_duration_seconds < 1 or p_duration_seconds > 7200 then
    raise exception 'Recording duration is invalid';
  end if;
  select * into v_interview from public.academy_interviews where id=p_interview_id for update;
  if not found then raise exception 'Interview assignment not found'; end if;
  select * into v_app from public.academy_applications where id=v_interview.application_id;
  if not found or v_app.user_id is distinct from auth.uid() then raise exception 'This interview is not assigned to your account'; end if;
  if v_interview.interview_type not in ('recorded_audio','recorded_video') then raise exception 'This interview does not accept a recording'; end if;
  if v_interview.status not in ('pending','scheduled','in_progress') then raise exception 'This interview is no longer accepting submissions'; end if;
  if p_media_path not like p_interview_id::text||'/'||auth.uid()::text||'/%' then raise exception 'Invalid private media path'; end if;
  if not exists(select 1 from storage.objects o where o.bucket_id='academy-interviews' and o.name=p_media_path) then
    raise exception 'Uploaded recording could not be found';
  end if;
  update public.academy_interviews
  set media_object_path=p_media_path,
      media_duration_seconds=p_duration_seconds,
      consented_at=now(),
      consent_policy_version='creatorverse-academy-interview-consent-2026-11',
      submitted_at=now(),
      status='submitted',
      updated_at=now()
  where id=p_interview_id;
  update public.academy_interview_invitations
  set applicant_submitted_at=now(), updated_at=now()
  where interview_id=p_interview_id and user_id=auth.uid();
  return jsonb_build_object('success',true,'status','submitted');
end
$$;
revoke all on function public.submit_academy_interview_response(uuid,text,integer,boolean) from public, anon;
grant execute on function public.submit_academy_interview_response(uuid,text,integer,boolean) to authenticated;
