-- Refine notification routing: avoid duplicate admin alerts for the initial
-- submission event and use the actual unified admin route.
create or replace function public.notify_academy_application_events()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_app public.academy_applications%rowtype; v_title text; v_body text;
begin
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  if new.event_type='submitted' then return new; end if;
  if new.actor_id is not null and new.actor_id=v_app.user_id then
    v_title:='Academy application needs attention';
    v_body:=coalesce(nullif(new.message,''),'An applicant has updated application '||v_app.application_no||'.');
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    select p.id,new.actor_id,'academy_application_activity',v_title,v_body,'/admin.html','academy_application',v_app.id
    from public.profiles p where p.role in ('super_admin','admin');
  else
    v_title:=case when new.to_status='approved' then 'Your application has been approved'
      when new.to_status='rejected' then 'An update on your application'
      when new.to_status='needs_information' then 'More information requested'
      when new.to_status='interview' then 'Your application has progressed to interview'
      else 'Your Academy application has been updated' end;
    v_body:=coalesce(nullif(new.message,''),'There is a new update on application '||v_app.application_no||'. Open your Academy status page.');
    insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
    values(v_app.user_id,new.actor_id,'academy_application_update',v_title,v_body,'/academy-status.html','academy_application',v_app.id);
  end if;
  return new;
end $$;
create or replace function public.notify_academy_application_submission()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
begin
  if new.submitted_at is null then return new; end if;
  if tg_op='UPDATE' and old.submitted_at is not distinct from new.submitted_at
     and old.status is not distinct from new.status then return new; end if;
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  select p.id,new.user_id,'academy_application_submitted','New Academy application received',
    'Application '||new.application_no||' has been submitted and is awaiting review.',
    '/admin.html','academy_application',new.id
  from public.profiles p where p.role in ('super_admin','admin')
  and not exists(select 1 from public.cv_notifications n where n.user_id=p.id
    and n.type='academy_application_submitted' and n.entity_type='academy_application' and n.entity_id=new.id);
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  select new.user_id,null,'academy_application_received','Application submitted successfully',
    'Your application '||new.application_no||' has been received. Follow its progress from your Academy status page.',
    '/academy-status.html','academy_application',new.id
  where not exists(select 1 from public.cv_notifications n where n.user_id=new.user_id
    and n.type='academy_application_received' and n.entity_type='academy_application' and n.entity_id=new.id);
  return new;
end $$;
create or replace function public.notify_academy_interview_reschedule()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_app public.academy_applications%rowtype;
begin
  if new.status<>'reschedule_requested' then return new; end if;
  if tg_op='UPDATE' and old.status is not distinct from new.status then return new; end if;
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  select p.id,new.user_id,'academy_interview_reschedule','Applicant requested an interview reschedule',
    'The applicant for '||v_app.application_no||' has requested a new interview time.',
    '/admin.html','academy_interview',new.interview_id
  from public.profiles p where p.role in ('super_admin','admin');
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  select i.reviewer_id,new.user_id,'academy_interview_reschedule','Interview reschedule requested',
    'The applicant for '||v_app.application_no||' has requested a new interview time.',
    '/notifications.html','academy_interview',new.interview_id
  from public.academy_interviews i where i.id=new.interview_id and i.reviewer_id is not null;
  return new;
end $$;
create or replace function public.notify_academy_interviewer_assignment()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_app public.academy_applications%rowtype;
begin
  if new.reviewer_id is null then return new; end if;
  if tg_op='UPDATE' and old.reviewer_id is not distinct from new.reviewer_id then return new; end if;
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  values(new.reviewer_id,auth.uid(),'academy_interview_assigned','New applicant interview assigned',
    'You have been assigned to review application '||v_app.application_no||'. Your assignment details are in CreatorVerse notifications.',
    '/notifications.html','academy_interview',new.id);
  return new;
end $$;