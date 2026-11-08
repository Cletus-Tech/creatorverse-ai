-- Unified Academy notification routing.
-- Academy lifecycle notifications are mirrored into the existing CreatorVerse
-- notification centre, while application and interviewer events are routed to
-- the correct individual recipients. Existing records are left untouched.

create or replace function public.mirror_academy_notification_to_creatorverse()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.cv_notifications
    (user_id, actor_id, type, title, body, href, entity_type, entity_id, created_at)
  values
    (new.user_id, null, 'academy_' || new.notification_type, new.title, new.body,
     coalesce(new.action_url, '/academy-status.html'),
     case when new.related_interview_id is not null then 'academy_interview'
          when new.related_offer_id is not null then 'academy_offer'
          when new.related_application_id is not null then 'academy_application'
          else 'academy' end,
     coalesce(new.related_interview_id, new.related_offer_id, new.related_application_id),
     new.created_at);
  return new;
end;
$$;

drop trigger if exists academy_notification_to_cv on public.academy_notifications;
create trigger academy_notification_to_cv
after insert on public.academy_notifications
for each row execute function public.mirror_academy_notification_to_creatorverse();

create or replace function public.notify_academy_application_submission()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_title text;
  v_body text;
begin
  if new.submitted_at is null then return new; end if;
  if tg_op = 'UPDATE' and old.submitted_at is not distinct from new.submitted_at
     and old.status is not distinct from new.status then return new; end if;

  v_title := 'New Academy application received';
  v_body := 'Application ' || new.application_no || ' has been submitted and is awaiting review.';
  insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
  select p.id, new.user_id, 'academy_application_submitted', v_title, v_body,
         '/admissions-admin.html', 'academy_application', new.id
  from public.profiles p
  where p.role in ('super_admin','admin')
    and not exists (
      select 1 from public.cv_notifications n
      where n.user_id=p.id and n.type='academy_application_submitted'
        and n.entity_type='academy_application' and n.entity_id=new.id
    );

  insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
  select new.user_id, null, 'academy_application_received',
         'Application submitted successfully',
         'Your application ' || new.application_no || ' has been received. You can follow its progress from your Academy status page.',
         '/academy-status.html', 'academy_application', new.id
  where not exists (
    select 1 from public.cv_notifications n
    where n.user_id=new.user_id and n.type='academy_application_received'
      and n.entity_type='academy_application' and n.entity_id=new.id
  );
  return new;
end;
$$;

drop trigger if exists academy_application_submission_notifications on public.academy_applications;
create trigger academy_application_submission_notifications
after insert or update of submitted_at, status on public.academy_applications
for each row execute function public.notify_academy_application_submission();

create or replace function public.notify_academy_application_events()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_app public.academy_applications%rowtype;
  v_title text;
  v_body text;
  v_href text;
begin
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  if new.actor_id is not null and new.actor_id=v_app.user_id then
    v_title := 'Academy application needs attention';
    v_body := coalesce(nullif(new.message,''), 'An applicant has updated application ' || v_app.application_no || '.');
    v_href := '/admissions-admin.html';
    insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
    select p.id, new.actor_id, 'academy_application_activity', v_title, v_body, v_href, 'academy_application', v_app.id
    from public.profiles p where p.role in ('super_admin','admin');
  else
    v_title := case
      when new.to_status='approved' then 'Your application has been approved'
      when new.to_status='rejected' then 'An update on your application'
      when new.to_status='needs_information' then 'More information requested'
      when new.to_status='interview' then 'Your application has progressed to interview'
      else 'Your Academy application has been updated'
    end;
    v_body := coalesce(nullif(new.message,''), 'There is a new update on application ' || v_app.application_no || '. Open your Academy status page to review it.');
    v_href := '/academy-status.html';
    insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
    values(v_app.user_id, new.actor_id, 'academy_application_update', v_title, v_body, v_href, 'academy_application', v_app.id);
  end if;
  return new;
end;
$$;

drop trigger if exists academy_application_event_notifications on public.academy_application_events;
create trigger academy_application_event_notifications
after insert on public.academy_application_events
for each row execute function public.notify_academy_application_events();

create or replace function public.notify_academy_interviewer_assignment()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_app public.academy_applications%rowtype;
begin
  if new.reviewer_id is null then return new; end if;
  if tg_op='UPDATE' and old.reviewer_id is not distinct from new.reviewer_id then return new; end if;
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
  values(new.reviewer_id, auth.uid(), 'academy_interview_assigned',
         'New applicant interview assigned',
         'You have been assigned to review application ' || v_app.application_no || '. Open the Academy interviewer workspace to view the assignment.',
         '/academy-interviewer.html', 'academy_interview', new.id);
  return new;
end;
$$;

drop trigger if exists academy_interviewer_assignment_notifications on public.academy_interviews;
create trigger academy_interviewer_assignment_notifications
after insert or update of reviewer_id on public.academy_interviews
for each row execute function public.notify_academy_interviewer_assignment();

create or replace function public.notify_academy_interview_reschedule()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_app public.academy_applications%rowtype;
begin
  if new.status <> 'reschedule_requested' then return new; end if;
  if tg_op='UPDATE' and old.status is not distinct from new.status then return new; end if;
  select * into v_app from public.academy_applications where id=new.application_id;
  if not found then return new; end if;
  insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
  select p.id, new.user_id, 'academy_interview_reschedule',
         'Applicant requested an interview reschedule',
         'The applicant for ' || v_app.application_no || ' has requested a new interview time.',
         '/admissions-admin.html', 'academy_interview', new.interview_id
  from public.profiles p where p.role in ('super_admin','admin');
  if exists(select 1 from public.academy_interviews i where i.id=new.interview_id and i.reviewer_id is not null) then
    insert into public.cv_notifications(user_id, actor_id, type, title, body, href, entity_type, entity_id)
    select i.reviewer_id, new.user_id, 'academy_interview_reschedule',
           'Interview reschedule requested',
           'The applicant for ' || v_app.application_no || ' has requested a new interview time.',
           '/academy-interviewer.html', 'academy_interview', new.interview_id
    from public.academy_interviews i where i.id=new.interview_id;
  end if;
  return new;
end;
$$;

drop trigger if exists academy_interview_reschedule_notifications on public.academy_interview_invitations;
create trigger academy_interview_reschedule_notifications
after insert or update of status on public.academy_interview_invitations
for each row execute function public.notify_academy_interview_reschedule();

-- Trigger functions are invoked only by their table triggers.
revoke all on function public.mirror_academy_notification_to_creatorverse() from public, anon, authenticated;
revoke all on function public.notify_academy_application_submission() from public, anon, authenticated;
revoke all on function public.notify_academy_application_events() from public, anon, authenticated;
revoke all on function public.notify_academy_interviewer_assignment() from public, anon, authenticated;
revoke all on function public.notify_academy_interview_reschedule() from public, anon, authenticated;
