-- Enforce the published response window and notify reviewers/admins when a
-- defence is submitted; notify the learner when assessment is completed.
create or replace function public.submit_academy_interview_response(
  p_interview_id uuid,
  p_media_path text,
  p_duration_seconds integer,
  p_consent boolean
) returns jsonb
language plpgsql security definer set search_path = pg_catalog, public
as $$
declare v_interview public.academy_interviews%rowtype; v_app public.academy_applications%rowtype;
        v_inv public.academy_interview_invitations%rowtype;
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
  select * into v_inv from public.academy_interview_invitations
    where interview_id=p_interview_id and user_id=auth.uid() and published_at is not null
    order by created_at desc limit 1;
  if not found then raise exception 'Published interview invitation not found'; end if;
  if now() < v_inv.starts_at then raise exception 'This assignment is not open yet'; end if;
  if now() > v_inv.ends_at then raise exception 'The submission deadline has passed'; end if;
  if v_interview.interview_type not in ('recorded_audio','recorded_video') then raise exception 'This interview does not accept a recording'; end if;
  if v_interview.status not in ('pending','scheduled','in_progress') then raise exception 'This interview is no longer accepting submissions'; end if;
  if p_media_path not like p_interview_id::text||'/'||auth.uid()::text||'/%' then raise exception 'Invalid private media path'; end if;
  if not exists(select 1 from storage.objects o where o.bucket_id='academy-interviews' and o.name=p_media_path) then
    raise exception 'Uploaded recording could not be found';
  end if;
  update public.academy_interviews
  set media_object_path=p_media_path,media_duration_seconds=p_duration_seconds,
      consented_at=now(),consent_policy_version='creatorverse-academy-interview-consent-2026-11',
      submitted_at=now(),status='submitted',updated_at=now()
  where id=p_interview_id;
  update public.academy_interview_invitations
  set applicant_submitted_at=now(),updated_at=now()
  where id=v_inv.id;
  return jsonb_build_object('success',true,'status','submitted');
end
$$;

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
      and inv.starts_at <= now() and inv.ends_at >= now()
      and i.interview_type in ('recorded_audio','recorded_video')
      and i.status in ('pending','scheduled','in_progress')
      and (storage.foldername(name))[2] = auth.uid()::text
  )
);

create or replace function public.notify_academy_interview_status()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_app public.academy_applications%rowtype; v_title text; v_body text;
begin
  if old.status is not distinct from new.status then return new; end if;
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  if new.status='submitted' then
    if new.reviewer_id is not null then
      insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
      values(new.reviewer_id,v_app.user_id,'academy_interview_response_submitted','Applicant defence submitted',
        'The applicant for '||v_app.application_no||' has submitted their defence. Open your assigned interview workspace.',
        '/academy-interviewer.html?interview='||new.id::text,'academy_interview',new.id);
    end if;
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    select p.id,v_app.user_id,'academy_interview_response_submitted','Academy defence submitted',
      'An applicant has submitted an interview response for application '||v_app.application_no||'.',
      '/admin.html','academy_interview',new.id
    from public.profiles p where p.role in ('super_admin','admin');
  elsif new.status='completed' then
    v_title:='Your Academy interview has been reviewed';
    v_body:='Your interview assessment is complete. Open your Academy admission status page to view the latest update.';
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_app.user_id,new.reviewer_id,'academy_interview_review_completed',v_title,v_body,
      '/academy-status.html','academy_interview',new.id);
  end if;
  return new;
end $$;
drop trigger if exists academy_interview_status_notifications on public.academy_interviews;
create trigger academy_interview_status_notifications
after update of status on public.academy_interviews
for each row execute function public.notify_academy_interview_status();
