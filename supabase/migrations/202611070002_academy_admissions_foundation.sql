-- CreatorVerse Academy admissions and placement foundation.
-- Additive only: preserves existing auth users, profiles, enrolments and academic records.
create table if not exists public.academy_applications (
 id uuid primary key default gen_random_uuid(),
 application_no text not null unique default ('CVA-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
 user_id uuid not null references auth.users(id) on delete restrict,
 course_id uuid not null references public.courses(id) on delete restrict,
 status text not null default 'draft' check(status in ('draft','submitted','under_review','more_information_requested','approved_pending_payment','approved','rejected','withdrawn')),
 first_name text not null,
 middle_name text,
 last_name text not null,
 phone text,
 country text,
 region text,
 education_level text,
 occupation text,
 prior_experience text,
 portfolio_url text,
 motivation text,
 learning_goals text,
 discovery_source text,
 certificate_name text,
 proposed_level text not null default 'Beginner' check(proposed_level in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 privacy_version text,
 consented_at timestamptz,
 submitted_at timestamptz,
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id) on delete set null,
 decision_reason text,
 admin_note text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists academy_applications_user_idx on public.academy_applications(user_id,created_at desc);
create index if not exists academy_applications_queue_idx on public.academy_applications(status,created_at desc);
create index if not exists academy_applications_course_idx on public.academy_applications(course_id,status);
alter table public.academy_applications enable row level security;
grant select,insert,update on public.academy_applications to authenticated;
drop policy if exists "Academy applicants read own applications" on public.academy_applications;
create policy "Academy applicants read own applications" on public.academy_applications for select to authenticated using(user_id=auth.uid() or public.is_admin());
drop policy if exists "Academy applicants create drafts" on public.academy_applications;
create policy "Academy applicants create drafts" on public.academy_applications for insert to authenticated with check(user_id=auth.uid() and status='draft');
drop policy if exists "Academy applicants update own drafts" on public.academy_applications;
create policy "Academy applicants update own drafts" on public.academy_applications for update to authenticated using(user_id=auth.uid() and status='draft') with check(user_id=auth.uid() and status in ('draft','submitted'));
drop policy if exists "Academy admins manage applications" on public.academy_applications;
create policy "Academy admins manage applications" on public.academy_applications for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_application_events (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null references public.academy_applications(id) on delete cascade,
 actor_id uuid references auth.users(id) on delete set null,
 event_type text not null,
 from_status text,
 to_status text,
 message text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists academy_application_events_app_idx on public.academy_application_events(application_id,created_at desc);
alter table public.academy_application_events enable row level security;
grant select,insert on public.academy_application_events to authenticated;
drop policy if exists "Applicants read application events" on public.academy_application_events;
create policy "Applicants read application events" on public.academy_application_events for select to authenticated using(exists(select 1 from public.academy_applications a where a.id=application_id and (a.user_id=auth.uid() or public.is_admin())));
drop policy if exists "Applicants append submission event" on public.academy_application_events;
create policy "Applicants append submission event" on public.academy_application_events for insert to authenticated with check(actor_id=auth.uid() and event_type='submitted' and exists(select 1 from public.academy_applications a where a.id=application_id and a.user_id=auth.uid() and a.status='submitted'));
drop policy if exists "Admins manage application events" on public.academy_application_events;
create policy "Admins manage application events" on public.academy_application_events for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_diagnostic_questions (
 id uuid primary key default gen_random_uuid(),
 course_id uuid not null references public.courses(id) on delete cascade,
 target_level text check(target_level is null or target_level in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 prompt text not null,
 response_type text not null default 'long_text' check(response_type in ('short_text','long_text','url','single_choice')),
 options jsonb not null default '[]'::jsonb,
 required boolean not null default true,
 position integer not null default 1,
 active boolean not null default true,
 published boolean not null default false,
 rubric jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists academy_diagnostic_questions_course_idx on public.academy_diagnostic_questions(course_id,published,position);
alter table public.academy_diagnostic_questions enable row level security;
grant select,insert,update,delete on public.academy_diagnostic_questions to authenticated;
drop policy if exists "Applicants view published diagnostic questions" on public.academy_diagnostic_questions;
create policy "Applicants view published diagnostic questions" on public.academy_diagnostic_questions for select to authenticated using(published and active or public.is_admin());
drop policy if exists "Admins manage diagnostic questions" on public.academy_diagnostic_questions;
create policy "Admins manage diagnostic questions" on public.academy_diagnostic_questions for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_diagnostic_responses (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null references public.academy_applications(id) on delete cascade,
 question_id uuid not null references public.academy_diagnostic_questions(id) on delete restrict,
 response_text text,
 response_url text,
 submitted_at timestamptz not null default now(),
 reviewer_score numeric(7,2),
 reviewer_feedback text,
 reviewed_by uuid references auth.users(id) on delete set null,
 reviewed_at timestamptz,
 unique(application_id,question_id)
);
create index if not exists academy_diagnostic_responses_app_idx on public.academy_diagnostic_responses(application_id);
alter table public.academy_diagnostic_responses enable row level security;
grant select,insert,update on public.academy_diagnostic_responses to authenticated;
drop policy if exists "Applicants read own diagnostic responses" on public.academy_diagnostic_responses;
create policy "Applicants read own diagnostic responses" on public.academy_diagnostic_responses for select to authenticated using(exists(select 1 from public.academy_applications a where a.id=application_id and (a.user_id=auth.uid() or public.is_admin())));
drop policy if exists "Applicants submit own diagnostic responses" on public.academy_diagnostic_responses;
create policy "Applicants submit own diagnostic responses" on public.academy_diagnostic_responses for insert to authenticated with check(exists(select 1 from public.academy_applications a where a.id=application_id and a.user_id=auth.uid() and a.status in ('draft','submitted','more_information_requested')));
drop policy if exists "Admins manage diagnostic responses" on public.academy_diagnostic_responses;
create policy "Admins manage diagnostic responses" on public.academy_diagnostic_responses for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_interviews (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null references public.academy_applications(id) on delete cascade,
 interview_type text not null check(interview_type in ('recorded_video','recorded_audio','live','alternative')),
 status text not null default 'pending' check(status in ('pending','scheduled','in_progress','submitted','completed','cancelled','declined')),
 prompt_snapshot jsonb not null default '[]'::jsonb,
 media_object_path text,
 media_duration_seconds integer,
 consented_at timestamptz,
 consent_policy_version text,
 retention_until timestamptz,
 scheduled_start timestamptz,
 scheduled_end timestamptz,
 timezone text,
 meeting_provider text,
 meeting_reference text,
 reviewer_id uuid references auth.users(id) on delete set null,
 reviewer_notes text,
 score numeric(7,2),
 submitted_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists academy_interviews_app_idx on public.academy_interviews(application_id,created_at desc);
alter table public.academy_interviews enable row level security;
grant select,insert,update on public.academy_interviews to authenticated;
drop policy if exists "Applicants read own interview metadata" on public.academy_interviews;
create policy "Applicants read own interview metadata" on public.academy_interviews for select to authenticated using(exists(select 1 from public.academy_applications a where a.id=application_id and (a.user_id=auth.uid() or public.is_admin())));
drop policy if exists "Admins manage interviews" on public.academy_interviews;
create policy "Admins manage interviews" on public.academy_interviews for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_placements (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null unique references public.academy_applications(id) on delete cascade,
 confirmed_level text not null check(confirmed_level in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 recommended_level text check(recommended_level is null or recommended_level in ('Beginner','Foundation','Intermediate','Advanced','Professional')),
 diagnostic_score numeric(7,2),
 interview_score numeric(7,2),
 portfolio_score numeric(7,2),
 rationale text not null,
 assigned_by uuid not null references auth.users(id) on delete restrict,
 assigned_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.academy_placements enable row level security;
grant select,insert,update on public.academy_placements to authenticated;
drop policy if exists "Applicants read own placement" on public.academy_placements;
create policy "Applicants read own placement" on public.academy_placements for select to authenticated using(exists(select 1 from public.academy_applications a where a.id=application_id and (a.user_id=auth.uid() or public.is_admin())));
drop policy if exists "Admins manage placements" on public.academy_placements;
create policy "Admins manage placements" on public.academy_placements for all to authenticated using(public.is_admin()) with check(public.is_admin());

create table if not exists public.academy_audit_log (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references auth.users(id) on delete set null,
 application_id uuid references public.academy_applications(id) on delete set null,
 action text not null,
 details jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
create index if not exists academy_audit_log_created_idx on public.academy_audit_log(created_at desc);
create index if not exists academy_audit_log_application_idx on public.academy_audit_log(application_id,created_at desc);
alter table public.academy_audit_log enable row level security;
grant select,insert on public.academy_audit_log to authenticated;
drop policy if exists "Admins read academy audit log" on public.academy_audit_log;
create policy "Admins read academy audit log" on public.academy_audit_log for select to authenticated using(public.is_admin());
drop policy if exists "Admins append academy audit log" on public.academy_audit_log;
create policy "Admins append academy audit log" on public.academy_audit_log for insert to authenticated with check(public.is_admin() and actor_id=auth.uid());

-- A dedicated private bucket for interview media. Object access policies are
-- intentionally deferred until signed-URL server-side authorisation is implemented.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('academy-interviews','academy-interviews',false,104857600,array['video/webm','video/mp4','audio/webm','audio/mp4','audio/mpeg','audio/wav'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
