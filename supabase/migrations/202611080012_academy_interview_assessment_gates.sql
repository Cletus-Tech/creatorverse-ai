create or replace function public.submit_academy_interview_review(
  p_interview_id uuid,
  p_score numeric,
  p_reviewer_notes text,
  p_completed boolean default true
) returns jsonb
language plpgsql security definer set search_path = pg_catalog, public
as $$
declare v_interview public.academy_interviews%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into v_interview from public.academy_interviews where id=p_interview_id for update;
  if not found then raise exception 'Interview not found'; end if;
  if not public.is_admin() and v_interview.reviewer_id is distinct from auth.uid() then
    raise exception 'You are not assigned to review this interview';
  end if;
  if v_interview.interview_type in ('recorded_audio','recorded_video') and v_interview.status <> 'submitted' then
    raise exception 'The applicant must submit the recording before it can be assessed';
  end if;
  if v_interview.interview_type='live' and v_interview.status <> 'in_progress' then
    raise exception 'Start the live interview room before completing its assessment';
  end if;
  if p_score is not null and (p_score < 0 or p_score > 100) then
    raise exception 'Score must be between 0 and 100';
  end if;
  update public.academy_interviews
  set score=p_score,
      reviewer_notes=nullif(btrim(p_reviewer_notes),''),
      status=case when p_completed then 'completed' else 'submitted' end,
      updated_at=now()
  where id=p_interview_id;
  return jsonb_build_object('success',true,'status',case when p_completed then 'completed' else 'submitted' end);
end
$$;
revoke all on function public.submit_academy_interview_review(uuid,numeric,text,boolean) from public, anon;
grant execute on function public.submit_academy_interview_review(uuid,numeric,text,boolean) to authenticated;
