create or replace function public.mark_academy_live_interview_started(p_interview_id uuid)
returns jsonb language plpgsql security definer set search_path = pg_catalog, public
as $$
declare v public.academy_interviews%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into v from public.academy_interviews where id=p_interview_id for update;
  if not found then raise exception 'Interview not found'; end if;
  if v.interview_type <> 'live' then raise exception 'This is not a live interview'; end if;
  if not public.is_admin() and v.reviewer_id is distinct from auth.uid() then
    raise exception 'Only the assigned interviewer can start this session';
  end if;
  if v.status not in ('pending','scheduled','in_progress') then
    raise exception 'This live interview is not available to start';
  end if;
  update public.academy_interviews set status='in_progress',updated_at=now() where id=p_interview_id;
  return jsonb_build_object('success',true,'status','in_progress');
end
$$;
revoke all on function public.mark_academy_live_interview_started(uuid) from public, anon;
grant execute on function public.mark_academy_live_interview_started(uuid) to authenticated;
