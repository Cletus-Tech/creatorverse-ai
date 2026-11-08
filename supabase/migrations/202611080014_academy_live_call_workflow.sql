-- Live interview control room and incoming call workflow.
create table if not exists public.academy_live_calls (
  id uuid primary key default gen_random_uuid(),
  interview_id uuid not null references public.academy_interviews(id) on delete cascade,
  caller_id uuid not null references auth.users(id) on delete restrict,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'ringing' check (status in ('ringing','accepted','declined','missed','cancelled','ended')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now()+interval '90 seconds'),
  responded_at timestamptz
);
create index if not exists academy_live_calls_recipient_active_idx on public.academy_live_calls(recipient_id,status,expires_at desc);
create unique index if not exists academy_live_calls_one_active_per_interview on public.academy_live_calls(interview_id) where status='ringing';
alter table public.academy_live_calls enable row level security;
revoke all on public.academy_live_calls from anon,authenticated;
drop policy if exists "No direct client access to Academy live calls" on public.academy_live_calls;
create policy "No direct client access to Academy live calls" on public.academy_live_calls for all to authenticated using (false) with check (false);

create or replace function public.ring_academy_live_interview(p_interview_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v public.academy_interviews%rowtype; a public.academy_applications%rowtype; active_id uuid; new_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into v from public.academy_interviews where id=p_interview_id for update;
 if not found then raise exception 'Interview not found'; end if;
 if v.interview_type<>'live' then raise exception 'This is not a live interview'; end if;
 if not public.is_admin() and v.reviewer_id is distinct from auth.uid() then raise exception 'Only the assigned interviewer or an administrator can ring the applicant'; end if;
 if v.status not in ('pending','scheduled','in_progress') then raise exception 'This interview is not available for a live call'; end if;
 select * into a from public.academy_applications where id=v.application_id;
 if not found then raise exception 'Applicant record not found'; end if;
 update public.academy_live_calls set status='missed',responded_at=now() where interview_id=p_interview_id and status='ringing' and expires_at<=now();
 select id into active_id from public.academy_live_calls where interview_id=p_interview_id and status='ringing' and expires_at>now() order by created_at desc limit 1;
 if active_id is not null then return jsonb_build_object('success',true,'call_id',active_id,'already_ringing',true); end if;
 insert into public.academy_live_calls(interview_id,caller_id,recipient_id,status,expires_at) values(p_interview_id,auth.uid(),a.user_id,'ringing',now()+interval '90 seconds') returning id into new_id;
 insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
 values(a.user_id,auth.uid(),'academy_live_call','Your Academy interviewer is calling','Your live interview is ready. Join the secure CreatorVerse interview room now.','/academy-live-room.html?interview='||p_interview_id::text,'academy_interview',p_interview_id);
 return jsonb_build_object('success',true,'call_id',new_id,'already_ringing',false,'expires_at',now()+interval '90 seconds');
end $$;
revoke all on function public.ring_academy_live_interview(uuid) from public,anon;
grant execute on function public.ring_academy_live_interview(uuid) to authenticated;

create or replace function public.get_my_active_academy_live_call()
returns table(call_id uuid,interview_id uuid,caller_name text,topic text,application_no text,expires_at timestamptz)
language plpgsql stable security definer set search_path=pg_catalog,public as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 return query select c.id,c.interview_id,coalesce(p.full_name,'CreatorVerse Academy'),i.topic,a.application_no,c.expires_at
 from public.academy_live_calls c join public.academy_interviews i on i.id=c.interview_id
 join public.academy_applications a on a.id=i.application_id left join public.profiles p on p.id=c.caller_id
 where c.recipient_id=auth.uid() and c.status='ringing' and c.expires_at>now()
 order by c.created_at desc limit 1;
end $$;
revoke all on function public.get_my_active_academy_live_call() from public,anon;
grant execute on function public.get_my_active_academy_live_call() to authenticated;

create or replace function public.respond_academy_live_call(p_call_id uuid,p_response text)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v public.academy_live_calls%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if p_response not in ('accepted','declined') then raise exception 'Invalid call response'; end if;
 select * into v from public.academy_live_calls where id=p_call_id for update;
 if not found or v.recipient_id<>auth.uid() then raise exception 'This call is not addressed to your account'; end if;
 if v.status<>'ringing' then raise exception 'This call is no longer active'; end if;
 if v.expires_at<=now() then update public.academy_live_calls set status='missed',responded_at=now() where id=p_call_id; raise exception 'This call has expired'; end if;
 update public.academy_live_calls set status=p_response,responded_at=now() where id=p_call_id;
 return jsonb_build_object('success',true,'status',p_response,'interview_id',v.interview_id);
end $$;
revoke all on function public.respond_academy_live_call(uuid,text) from public,anon;
grant execute on function public.respond_academy_live_call(uuid,text) to authenticated;

create or replace function public.cancel_academy_live_call(p_call_id uuid)
returns jsonb language plpgsql security definer set search_path=pg_catalog,public as $$
declare v public.academy_live_calls%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into v from public.academy_live_calls where id=p_call_id for update;
 if not found then raise exception 'Call not found'; end if;
 if not public.is_admin() and v.caller_id<>auth.uid() then raise exception 'Only the caller or an administrator can cancel this call'; end if;
 if v.status='ringing' then update public.academy_live_calls set status='cancelled',responded_at=now() where id=p_call_id; end if;
 return jsonb_build_object('success',true);
end $$;
revoke all on function public.cancel_academy_live_call(uuid) from public,anon;
grant execute on function public.cancel_academy_live_call(uuid) to authenticated;
