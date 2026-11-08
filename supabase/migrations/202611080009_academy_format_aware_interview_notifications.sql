create or replace function public.notify_academy_interview_changes()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_kind text; v_title text; v_body text;
begin
 if new.published_at is not null and (tg_op='INSERT' or old.published_at is null or old.starts_at is distinct from new.starts_at) then
  v_kind:=new.interview_type;
  if v_kind='recorded_audio' then
    v_title:='Audio defence assignment published';
    v_body:='Your audio defence topic and instructions are ready. Submit your recording by '||to_char(new.ends_at,'Dy, DD Mon YYYY HH24:MI')||' ('||new.timezone||'). Open your Academy status page to begin.';
  elsif v_kind='recorded_video' then
    v_title:='Audiovisual defence assignment published';
    v_body:='Your audiovisual defence topic and instructions are ready. Submit your video by '||to_char(new.ends_at,'Dy, DD Mon YYYY HH24:MI')||' ('||new.timezone||'). Open your Academy status page to begin.';
  else
    v_title:='Your live Academy interview is scheduled';
    v_body:='Your live interview is scheduled for '||to_char(new.starts_at,'Dy, DD Mon YYYY HH24:MI')||' ('||new.timezone||'). Enter the private interview room from your Academy status page.';
  end if;
  insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_interview_id,scheduled_for,dedupe_key)
  values(new.user_id,'interview_scheduled',v_title,v_body,new.application_id,new.id,now(),'interview-issued:'||new.id::text||':'||new.starts_at::text)
  on conflict(dedupe_key) do nothing;
  if v_kind in ('recorded_audio','recorded_video') then
    insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_interview_id,scheduled_for,dedupe_key)
    values(new.user_id,'interview_reminder','Defence submission deadline — 24 hours','Your defence response deadline is approaching. Open the assignment and submit your recording before the deadline.',new.application_id,new.id,greatest(now(),new.ends_at-interval '24 hours'),'interview-reminder-24h:'||new.id::text||':'||new.starts_at::text)
    on conflict(dedupe_key) do nothing;
    insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_interview_id,scheduled_for,dedupe_key)
    values(new.user_id,'interview_reminder','Defence submission deadline — 1 hour','Your defence response is due in about one hour. Please submit before the deadline.',new.application_id,new.id,greatest(now(),new.ends_at-interval '1 hour'),'interview-reminder-1h:'||new.id::text||':'||new.starts_at::text)
    on conflict(dedupe_key) do nothing;
  else
    insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_interview_id,scheduled_for,dedupe_key)
    values(new.user_id,'interview_reminder','Live interview reminder — 24 hours','Your live Academy interview is approaching. Enter the private interview room at the scheduled time.',new.application_id,new.id,greatest(now(),new.starts_at-interval '24 hours'),'interview-reminder-24h:'||new.id::text||':'||new.starts_at::text)
    on conflict(dedupe_key) do nothing;
    insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_interview_id,scheduled_for,dedupe_key)
    values(new.user_id,'interview_reminder','Live interview reminder — 1 hour','Your live Academy interview starts in about one hour. Please be ready to join.',new.application_id,new.id,greatest(now(),new.starts_at-interval '1 hour'),'interview-reminder-1h:'||new.id::text||':'||new.starts_at::text)
    on conflict(dedupe_key) do nothing;
  end if;
 elsif tg_op='UPDATE' and old.status is distinct from new.status and new.status='missed' then
  insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_interview_id,dedupe_key)
  values(new.user_id,'interview_missed','Academy interview marked missed','Our records show that the scheduled interview was missed. Contact Academy admissions to discuss the next step.',new.application_id,new.id,'interview-missed:'||new.id::text)
  on conflict(dedupe_key) do nothing;
 end if;
 return new;
end $$;
