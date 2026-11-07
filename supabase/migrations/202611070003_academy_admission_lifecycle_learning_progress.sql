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
 if tg_op='INSERT' or (old.completed_at is null and new.completed_at is not null) then
  insert into public.academy_learning_activity(user_id,course_id,lesson_id,activity_type,source_record_id)
  values(new.user_id,v_course,new.lesson_id,'lesson_completed',new.user_id::text||':'||new.lesson_id::text)
  on conflict do nothing;
 elsif old.completed_at is not null and new.completed_at is null then
  insert into public.academy_learning_activity(user_id,course_id,lesson_id,activity_type,source_record_id)
  values(new.user_id,v_course,new.lesson_id,'lesson_reopened',new.user_id::text||':'||new.lesson_id::text||':'||extract(epoch from clock_timestamp())::text);
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
