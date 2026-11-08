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
    'You have been assigned to review application '||v_app.application_no||'. Open your assigned interview workspace in CreatorVerse.',
    '/academy-interviewer.html?interview='||new.id::text,'academy_interview',new.id);
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
    '/academy-interviewer.html?interview='||i.id::text,'academy_interview',new.interview_id
  from public.academy_interviews i where i.id=new.interview_id and i.reviewer_id is not null;
  return new;
end $$;
