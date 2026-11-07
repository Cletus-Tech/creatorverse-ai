-- CreatorVerse Academy: admission acceptance windows, learner monitoring and level progression.
-- Draft only. Additive; does not alter existing enrolments or student records.
alter table public.academy_applications
 add column if not exists offer_issued_at timestamptz,
 add column if not exists offer_expires_at timestamptz,
 add column if not exists offer_accepted_at timestamptz,
 add column if not exists offer_declined_at timestamptz,
 add column if not exists admission_cohort text;

create table if not exists public.academy_admission_offers (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null unique references public.academy_applications(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 status text not null default 'offered' check(status in ('offered','accepted','declined','expired','withdrawn')),
 issued_at timestamptz not null default now(),
 expires_at timestamptz not null,
 accepted_at timestamptz,
 declined_at timestamptz,
 offer_message text,
 terms_version text,
 issued_by uuid not null references auth.users(id) on delete restrict,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(expires_at>issued_at),
 check(accepted_at is null or accepted_at<=expires_at),
 check(declined_at is null or declined_at<=expires_at)
);
create index if not exists academy_admission_offers_user_idx on public.academy_admission_offers(user_id,status,expires_at);
alter table public.academy_admission_offers enable row level security;
grant select,insert,update on public.academy_admission_offers to authenticated;
drop policy if exists "Learners read own admission offers" on public.academy_admission_offers;
create policy "Learners read own admission offers" on public.academy_admission_offers for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "Admins manage admission offers" on public.academy_admission_offers;
create policy "Admins manage admission offers" on public.academy_admission_offers for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Applicant-safe interview invitation projection. Private meeting/reviewer/media fields stay in academy_interviews.
create table if not exists public.academy_interview_invitations (
 id uuid primary key default gen_random_uuid(),
 interview_id uuid not null unique references public.academy_interviews(id) on delete cascade,
 application_id uuid not null references public.academy_applications(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete restrict,
 interview_type text not null check(interview_type in ('live','recorded_video','recorded_audio','alternative')),
 status text not null default 'scheduled' check(status in ('scheduled','confirmed','reschedule_requested','attended','missed','cancelled')),
 starts_at timestamptz not null,
 ends_at timestamptz not null,
 timezone text not null,
 attendance_deadline timestamptz,
 learner_instructions text,
 published_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(ends_at>starts_at),
 check(attendance_deadline is null or attendance_deadline>=starts_at)
);
create index if not exists academy_interview_invitations_user_idx on public.academy_interview_invitations(user_id,starts_at);
alter table public.academy_interview_invitations enable row level security;
grant select,insert,update on public.academy_interview_invitations to authenticated;
drop policy if exists "Learners read own published interview invitations" on public.academy_interview_invitations;
create policy "Learners read own published interview invitations" on public.academy_interview_invitations for select to authenticated using((user_id=auth.uid() and published_at is not null) or public.is_admin());
drop policy if exists "Admins manage interview invitations" on public.academy_interview_invitations;
create policy "Admins manage interview invitations" on public.academy_interview_invitations for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Append-only learning activity. A trigger records completed lesson changes without trusting browser timestamps.
create table if not exists public.academy_learning_activity (
 id bigint generated always as identity primary key,
 user_id uuid not null references auth.users(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 lesson_id uuid references public.lessons(id) on delete set null,
 activity_type text not null check(activity_type in ('lesson_completed','lesson_reopened','lesson_viewed','quiz_submitted','assignment_submitted','level_unlocked','login')),
 source_record_id text,
 occurred_at timestamptz not null default now(),
 metadata jsonb not null default '{}'::jsonb
);
create index if not exists academy_learning_activity_user_course_idx on public.academy_learning_activity(user_id,course_id,occurred_at desc);
alter table public.academy_learning_activity enable row level security;
grant select,insert on public.academy_learning_activity to authenticated;
drop policy if exists "Learners read own learning activity" on public.academy_learning_activity;
create policy "Learners read own learning activity" on public.academy_learning_activity for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "Admins read all learning activity" on public.academy_learning_activity;
create policy "Admins read all learning activity" on public.academy_learning_activity for select to authenticated using(public.is_admin());
-- No direct client insert policy: trusted database triggers/functions will append activity.

create or replace function public.track_academy_lesson_progress()
returns trigger language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_course uuid;
begin
 select m.course_id into v_course from public.lessons l join public.modules m on m.id=l.module_id where l.id=new.lesson_id;
 if v_course is null then return new; end if;
 if tg_op='INSERT' then
  if new.completed_at is not null then
   insert into public.academy_learning_activity(user_id,course_id,lesson_id,activity_type,source_record_id)
   values(new.user_id,v_course,new.lesson_id,'lesson_completed',new.user_id::text||':'||new.lesson_id::text)
   on conflict do nothing;
  end if;
 elsif tg_op='UPDATE' then
  if old.completed_at is null and new.completed_at is not null then
   insert into public.academy_learning_activity(user_id,course_id,lesson_id,activity_type,source_record_id)
   values(new.user_id,v_course,new.lesson_id,'lesson_completed',new.user_id::text||':'||new.lesson_id::text)
   on conflict do nothing;
  elsif old.completed_at is not null and new.completed_at is null then
   insert into public.academy_learning_activity(user_id,course_id,lesson_id,activity_type,source_record_id)
   values(new.user_id,v_course,new.lesson_id,'lesson_reopened',new.user_id::text||':'||new.lesson_id::text||':'||extract(epoch from clock_timestamp())::text);
  end if;
 end if;
 return new;
end $$;
revoke all on function public.track_academy_lesson_progress() from public,anon,authenticated;
drop trigger if exists academy_track_lesson_progress on public.lesson_progress;
create trigger academy_track_lesson_progress after insert or update of completed_at on public.lesson_progress
for each row execute function public.track_academy_lesson_progress();

-- Admin-configurable progression rules; levels are unlocked only by a trusted progression evaluator.
create table if not exists public.academy_level_rules (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.courses(id) on delete cascade,
 level_name text not null check(level_name in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 sequence_no integer not null check(sequence_no between 1 and 5),
 min_completed_percent numeric(5,2) not null check(min_completed_percent between 0 and 100),
 min_quiz_average numeric(5,2) check(min_quiz_average is null or min_quiz_average between 0 and 100),
 min_assignment_count integer not null default 0 check(min_assignment_count>=0),
 min_active_days integer not null default 0 check(min_active_days>=0),
 requires_admin_approval boolean not null default true,
 published boolean not null default false,
 updated_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(course_id,level_name),
 unique(course_id,sequence_no)
);
alter table public.academy_level_rules enable row level security;
grant select,insert,update,delete on public.academy_level_rules to authenticated;
drop policy if exists "Learners read published level rules" on public.academy_level_rules;
create policy "Learners read published level rules" on public.academy_level_rules for select to authenticated using(published or public.is_admin());
drop policy if exists "Admins manage level rules" on public.academy_level_rules;
create policy "Admins manage level rules" on public.academy_level_rules for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_learner_levels (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 current_level text not null default 'Beginner' check(current_level in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 highest_unlocked_level text not null default 'Beginner' check(highest_unlocked_level in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 progress_percent numeric(5,2) not null default 0 check(progress_percent between 0 and 100),
 completed_lessons integer not null default 0 check(completed_lessons>=0),
 total_lessons integer not null default 0 check(total_lessons>=0),
 last_activity_at timestamptz,
 last_evaluated_at timestamptz,
 next_review_at timestamptz,
 admin_override boolean not null default false,
 admin_note text,
 updated_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(user_id,course_id)
);
alter table public.academy_learner_levels enable row level security;
grant select,insert,update on public.academy_learner_levels to authenticated;
drop policy if exists "Learners read own level progress" on public.academy_learner_levels;
create policy "Learners read own level progress" on public.academy_learner_levels for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "Admins manage learner levels" on public.academy_learner_levels;
create policy "Admins manage learner levels" on public.academy_learner_levels for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Admin-only monitoring view. Use security_invoker so underlying RLS is respected.
create or replace view public.academy_learner_activity_summary with (security_invoker=true) as
select e.user_id,e.course_id,c.title as course_title,
 count(distinct lp.lesson_id) filter(where lp.completed_at is not null)::integer as completed_lessons,
 count(distinct l.id)::integer as total_lessons,
 case when count(distinct l.id)=0 then 0 else round(100.0*count(distinct lp.lesson_id) filter(where lp.completed_at is not null)/count(distinct l.id),2) end as completion_percent,
 max(lp.completed_at) as last_lesson_completed_at,
 max(act.occurred_at) as last_activity_at
from public.enrolments e
join public.courses c on c.id=e.course_id
left join public.modules m on m.course_id=e.course_id
left join public.lessons l on l.module_id=m.id
left join public.lesson_progress lp on lp.user_id=e.user_id and lp.lesson_id=l.id
left join public.academy_learning_activity act on act.user_id=e.user_id and act.course_id=e.course_id
group by e.user_id,e.course_id,c.title;
revoke all on public.academy_learner_activity_summary from anon;
grant select on public.academy_learner_activity_summary to authenticated;


-- Learners can accept only their own live offer, before the deadline. This records acceptance;
-- course access still requires the separate verified payment/free-course fulfilment workflow.
create or replace function public.accept_academy_admission_offer(p_offer_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_offer public.academy_admission_offers%rowtype;
begin
 if auth.uid() is null then raise exception 'Sign in is required'; end if;
 select * into v_offer from public.academy_admission_offers where id=p_offer_id and user_id=auth.uid() for update;
 if not found then raise exception 'Admission offer not found'; end if;
 if v_offer.status<>'offered' then raise exception 'This offer is no longer awaiting acceptance'; end if;
 if v_offer.expires_at<=now() then
  update public.academy_admission_offers set status='expired',updated_at=now() where id=p_offer_id;
  return jsonb_build_object('status','expired','message','The acceptance deadline has passed. Contact Academy admissions.');
 end if;
 update public.academy_admission_offers set status='accepted',accepted_at=now(),updated_at=now() where id=p_offer_id;
 update public.academy_applications set offer_accepted_at=now(),updated_at=now() where id=v_offer.application_id and user_id=auth.uid();
 insert into public.academy_application_events(application_id,actor_id,event_type,message,metadata)
 values(v_offer.application_id,auth.uid(),'admission_offer_accepted','Learner accepted the admission offer.',jsonb_build_object('offer_id',p_offer_id,'accepted_at',now()));
 insert into public.academy_audit_log(actor_id,application_id,action,details)
 values(auth.uid(),v_offer.application_id,'admission_offer_accepted',jsonb_build_object('offer_id',p_offer_id));
 return jsonb_build_object('status','accepted','message','Admission offer accepted. Complete any required payment and onboarding steps to activate course access.');
end $$;
revoke all on function public.accept_academy_admission_offer(uuid) from public,anon;
grant execute on function public.accept_academy_admission_offer(uuid) to authenticated;

-- Learner can confirm an invitation or request a reschedule; only admins can mark attendance/missed.
create or replace function public.respond_to_academy_interview_invitation(p_invitation_id uuid,p_response text)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_inv public.academy_interview_invitations%rowtype;
begin
 if auth.uid() is null then raise exception 'Sign in is required'; end if;
 if p_response not in ('confirmed','reschedule_requested') then raise exception 'Unsupported response'; end if;
 select * into v_inv from public.academy_interview_invitations where id=p_invitation_id and user_id=auth.uid() and published_at is not null for update;
 if not found then raise exception 'Interview invitation not found'; end if;
 if v_inv.status not in ('scheduled','confirmed') then raise exception 'This interview invitation can no longer be changed'; end if;
 if v_inv.starts_at<=now() then raise exception 'The response window for this interview has closed'; end if;
 update public.academy_interview_invitations set status=p_response,updated_at=now() where id=p_invitation_id;
 insert into public.academy_application_events(application_id,actor_id,event_type,message,metadata)
 values(v_inv.application_id,auth.uid(),'interview_invitation_response','Learner response: '||p_response,jsonb_build_object('invitation_id',p_invitation_id));
 return jsonb_build_object('status',p_response);
end $$;
revoke all on function public.respond_to_academy_interview_invitation(uuid,text) from public,anon;
grant execute on function public.respond_to_academy_interview_invitation(uuid,text) to authenticated;


create table if not exists public.academy_level_unlock_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 level_name text not null check(level_name in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 progress_percent numeric(5,2) not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 requested_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id) on delete set null,
 reviewer_note text,
 unique(user_id,course_id,level_name)
);
alter table public.academy_level_unlock_requests enable row level security;
grant select,insert,update on public.academy_level_unlock_requests to authenticated;
drop policy if exists "Learners read own level unlock requests" on public.academy_level_unlock_requests;
create policy "Learners read own level unlock requests" on public.academy_level_unlock_requests for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "Admins manage level unlock requests" on public.academy_level_unlock_requests;
create policy "Admins manage level unlock requests" on public.academy_level_unlock_requests for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Re-evaluate a learner's progress after a lesson completion. Rule thresholds are configured by admins.
-- Rules requiring approval create a request instead of unlocking automatically.
create or replace function public.refresh_academy_learner_level(p_course_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public
as $$
declare
 v_user uuid:=auth.uid(); v_total integer; v_done integer; v_pct numeric(5,2); v_days integer;
 v_quiz numeric(5,2); v_assignments integer; v_current text:='Beginner'; v_highest text:='Beginner'; v_override boolean:=false;
 v_rule public.academy_level_rules%rowtype; v_pending text;
begin
 if v_user is null then raise exception 'Sign in is required'; end if;
 if not exists(select 1 from public.enrolments where user_id=v_user and course_id=p_course_id) then raise exception 'You must be enrolled in this course'; end if;
 select count(*)::integer into v_total from public.lessons l join public.modules m on m.id=l.module_id where m.course_id=p_course_id;
 select count(distinct lp.lesson_id)::integer into v_done from public.lesson_progress lp join public.lessons l on l.id=lp.lesson_id join public.modules m on m.id=l.module_id where lp.user_id=v_user and m.course_id=p_course_id and lp.completed_at is not null;
 v_pct:=case when v_total=0 then 0 else round(100.0*v_done/v_total,2) end;
 select count(distinct occurred_at::date)::integer into v_days from public.academy_learning_activity where user_id=v_user and course_id=p_course_id;
 select coalesce(avg(qa.score),0)::numeric(5,2) into v_quiz from public.quiz_attempts qa join public.quizzes q on q.id=qa.quiz_id where qa.user_id=v_user and q.course_id=p_course_id;
 select count(*)::integer into v_assignments from public.submissions s join public.assignments a on a.id=s.assignment_id where s.user_id=v_user and a.course_id=p_course_id and s.status in ('submitted','graded');
 select current_level,highest_unlocked_level,admin_override into v_current,v_highest,v_override from public.academy_learner_levels where user_id=v_user and course_id=p_course_id;
 v_current:=coalesce(v_current,'Beginner');v_highest:=coalesce(v_highest,'Beginner');v_override:=coalesce(v_override,false);
 select * into v_rule from public.academy_level_rules r where r.course_id=p_course_id and r.published=true and r.sequence_no>(select coalesce(max(x.sequence_no),0) from public.academy_level_rules x where x.course_id=p_course_id and x.level_name=v_highest)
 and r.min_completed_percent<=v_pct and r.min_active_days<=v_days and (r.min_quiz_average is null or v_quiz>=r.min_quiz_average) and v_assignments>=r.min_assignment_count
 order by r.sequence_no desc limit 1;
 insert into public.academy_learner_levels(user_id,course_id,current_level,highest_unlocked_level,progress_percent,completed_lessons,total_lessons,last_activity_at,last_evaluated_at,updated_at)
 values(v_user,p_course_id,v_current,v_highest,v_pct,v_done,v_total,now(),now(),now())
 on conflict(user_id,course_id) do update set progress_percent=excluded.progress_percent,completed_lessons=excluded.completed_lessons,total_lessons=excluded.total_lessons,last_activity_at=excluded.last_activity_at,last_evaluated_at=now(),updated_at=now();
 if v_rule.id is not null and not v_override then
  if v_rule.requires_admin_approval then
   insert into public.academy_level_unlock_requests(user_id,course_id,level_name,progress_percent)
   values(v_user,p_course_id,v_rule.level_name,v_pct) on conflict(user_id,course_id,level_name) do update set status='pending',progress_percent=excluded.progress_percent,requested_at=now() where public.academy_level_unlock_requests.status='rejected';
   v_pending:=v_rule.level_name;
  else
   update public.academy_learner_levels set current_level=v_rule.level_name,highest_unlocked_level=v_rule.level_name,updated_at=now() where user_id=v_user and course_id=p_course_id;
   insert into public.academy_learning_activity(user_id,course_id,activity_type,metadata) values(v_user,p_course_id,'level_unlocked',jsonb_build_object('level',v_rule.level_name));
   v_current:=v_rule.level_name;v_highest:=v_rule.level_name;
  end if;
 end if;
 return jsonb_build_object('progress_percent',v_pct,'completed_lessons',v_done,'total_lessons',v_total,'current_level',v_current,'highest_unlocked_level',v_highest,'pending_level',v_pending);
end $$;
revoke all on function public.refresh_academy_learner_level(uuid) from public,anon;
grant execute on function public.refresh_academy_learner_level(uuid) to authenticated;

alter table public.academy_admission_offers add column if not exists expires_timezone text;

alter table public.academy_interview_invitations add column if not exists meeting_join_url text;

-- Admin-triggered lifecycle sweeps. The admin workspace calls these when reviewing admissions;
-- a scheduled database job can be added later for fully automatic background expiry.
create or replace function public.expire_academy_admission_offers()
returns integer language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_count integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
 with expired as (
  update public.academy_admission_offers set status='expired',updated_at=now()
  where status='offered' and expires_at<=now()
  returning id,application_id
 )
 insert into public.academy_application_events(application_id,actor_id,event_type,message,metadata)
 select application_id,auth.uid(),'admission_offer_expired','Admission acceptance deadline passed.',jsonb_build_object('offer_id',id)
 from expired;
 get diagnostics v_count=row_count;
 return v_count;
end $$;
revoke all on function public.expire_academy_admission_offers() from public,anon;
grant execute on function public.expire_academy_admission_offers() to authenticated;

create or replace function public.expire_academy_interview_invitations()
returns integer language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_count integer;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Administrator access required'; end if;
 with missed as (
  update public.academy_interview_invitations set status='missed',updated_at=now()
  where status in ('scheduled','confirmed') and ends_at<=now()
  returning id,application_id,interview_id
 )
 insert into public.academy_application_events(application_id,actor_id,event_type,message,metadata)
 select application_id,auth.uid(),'interview_marked_missed','Interview appointment ended without attendance confirmation.',jsonb_build_object('invitation_id',id,'interview_id',interview_id)
 from missed;
 get diagnostics v_count=row_count;
 return v_count;
end $$;
revoke all on function public.expire_academy_interview_invitations() from public,anon;
grant execute on function public.expire_academy_interview_invitations() to authenticated;


-- Record lesson opens and assessment submissions as learning activity.
create or replace function public.record_academy_lesson_view(p_lesson_id uuid)
returns boolean language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_course uuid; v_user uuid:=auth.uid();
begin
 if v_user is null then raise exception 'Sign in is required'; end if;
 select m.course_id into v_course from public.lessons l join public.modules m on m.id=l.module_id where l.id=p_lesson_id;
 if v_course is null or not exists(select 1 from public.enrolments where user_id=v_user and course_id=v_course) then raise exception 'You are not enrolled in this course'; end if;
 if exists(select 1 from public.academy_learning_activity where user_id=v_user and course_id=v_course and lesson_id=p_lesson_id and activity_type='lesson_viewed' and occurred_at>now()-interval '5 minutes') then return false; end if;
 insert into public.academy_learning_activity(user_id,course_id,lesson_id,activity_type)
 values(v_user,v_course,p_lesson_id,'lesson_viewed');
 return true;
end $$;
revoke all on function public.record_academy_lesson_view(uuid) from public,anon;
grant execute on function public.record_academy_lesson_view(uuid) to authenticated;

create or replace function public.track_academy_assessment_activity()
returns trigger language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_course uuid; v_type text;
begin
 if tg_table_name='quiz_attempts' then
  select course_id into v_course from public.quizzes where id=new.quiz_id;
  v_type:='quiz_submitted';
 else
  select course_id into v_course from public.assignments where id=new.assignment_id;
  v_type:='assignment_submitted';
 end if;
 if v_course is not null then
  insert into public.academy_learning_activity(user_id,course_id,activity_type,source_record_id,metadata)
  values(new.user_id,v_course,v_type,new.id::text,jsonb_build_object('record_id',new.id));
 end if;
 return new;
end $$;
revoke all on function public.track_academy_assessment_activity() from public,anon,authenticated;
drop trigger if exists academy_track_quiz_attempt on public.quiz_attempts;
create trigger academy_track_quiz_attempt after insert on public.quiz_attempts
for each row execute function public.track_academy_assessment_activity();
drop trigger if exists academy_track_assignment_submission on public.submissions;
create trigger academy_track_assignment_submission after insert on public.submissions
for each row execute function public.track_academy_assessment_activity();
