create or replace function public.notify_academy_interview_status()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_app public.academy_applications%rowtype;
begin
  if old.status is not distinct from new.status then return new; end if;
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  if new.status='submitted' then
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_app.user_id,v_app.user_id,'academy_interview_response_received','Defence response submitted',
      'Your recording has been received securely. The assigned interviewer will review it and your Academy status will update.',
      '/academy-status.html','academy_interview',new.id);
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
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_app.user_id,new.reviewer_id,'academy_interview_review_completed','Your Academy interview has been reviewed',
      'Your interview assessment is complete. Open your Academy admission status page to view the latest update.',
      '/academy-status.html','academy_interview',new.id);
  end if;
  return new;
end $$;
