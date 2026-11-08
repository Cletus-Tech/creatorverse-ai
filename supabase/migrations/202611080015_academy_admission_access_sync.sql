-- Keep Academy admission, interview state, payments and course access in one lifecycle.
-- Free accepted offers activate enrolment immediately; paid offers remain locked until confirmed payment.

create or replace function public.accept_academy_admission_offer(p_offer_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=pg_catalog,public
as $$
declare
 v_offer public.academy_admission_offers%rowtype;
 v_course_price integer;
 v_course_title text;
 v_application_no text;
 v_now timestamptz := now();
 v_access_status text;
begin
 if auth.uid() is null then raise exception 'Sign in is required'; end if;
 select * into v_offer from public.academy_admission_offers
 where id=p_offer_id and user_id=auth.uid() for update;
 if not found then raise exception 'Admission offer not found'; end if;
 if v_offer.status='accepted' then
   select coalesce(c.price_ngn,0),c.title,a.application_no into v_course_price,v_course_title,v_application_no
   from public.academy_applications a join public.courses c on c.id=a.course_id
   where a.id=v_offer.application_id;
   if coalesce(v_course_price,0)<=0 then
     insert into public.enrolments(user_id,course_id) values(v_offer.user_id,v_offer.course_id)
     on conflict(user_id,course_id) do nothing;
     update public.academy_applications set status='approved',
       offer_accepted_at=coalesce(offer_accepted_at,v_offer.accepted_at,v_now),updated_at=v_now
     where id=v_offer.application_id;
     return jsonb_build_object('status','enrolled','message','Your free admission is active. Continue learning.');
   end if;
   return jsonb_build_object('status','approved_pending_payment','message','Your admission is accepted. Complete payment to activate course access.');
 end if;
 if v_offer.status<>'offered' then raise exception 'This offer is no longer awaiting acceptance'; end if;
 if v_offer.expires_at<=v_now then
   update public.academy_admission_offers set status='expired',updated_at=v_now where id=p_offer_id;
   return jsonb_build_object('status','expired','message','The acceptance deadline has passed. Contact Academy admissions.');
 end if;
 select coalesce(c.price_ngn,0),c.title,a.application_no into v_course_price,v_course_title,v_application_no
 from public.academy_applications a join public.courses c on c.id=a.course_id
 where a.id=v_offer.application_id and a.user_id=auth.uid();
 if not found then raise exception 'The course linked to this admission could not be found'; end if;
 update public.academy_admission_offers set status='accepted',accepted_at=v_now,updated_at=v_now where id=p_offer_id;
 if coalesce(v_course_price,0)<=0 then
   insert into public.enrolments(user_id,course_id) values(v_offer.user_id,v_offer.course_id)
   on conflict(user_id,course_id) do nothing;
   v_access_status := 'approved';
 else
   v_access_status := 'approved_pending_payment';
 end if;
 update public.academy_applications set status=v_access_status,offer_accepted_at=v_now,updated_at=v_now
 where id=v_offer.application_id and user_id=auth.uid();
 update public.academy_interview_invitations set status='cancelled',updated_at=v_now
 where application_id=v_offer.application_id and status not in ('cancelled','declined');
 update public.academy_interviews set status='cancelled',updated_at=v_now
 where application_id=v_offer.application_id and status not in ('cancelled','declined','completed','submitted');
 update public.academy_live_calls set status='cancelled',responded_at=v_now
 where interview_id in (select id from public.academy_interviews where application_id=v_offer.application_id)
 and status='ringing';
 insert into public.academy_application_events(application_id,actor_id,event_type,from_status,to_status,message,metadata)
 values(v_offer.application_id,auth.uid(),'admission_offer_accepted',null,v_access_status,
 case when v_access_status='approved' then 'Admission accepted. Free course enrolment activated automatically.'
 else 'Admission accepted. Payment is required before course access is activated.' end,
 jsonb_build_object('offer_id',p_offer_id,'accepted_at',v_now,'course_price_ngn',v_course_price));
 insert into public.academy_audit_log(actor_id,application_id,action,details)
 values(auth.uid(),v_offer.application_id,'admission_offer_accepted',
 jsonb_build_object('offer_id',p_offer_id,'course_price_ngn',v_course_price,'application_status',v_access_status));
 insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_offer_id,related_course_id,scheduled_for,dedupe_key,action_url)
 values(v_offer.user_id,
 case when v_access_status='approved' then 'admission_activated' else 'payment_required' end,
 case when v_access_status='approved' then 'Your admission is active' else 'Admission accepted — payment required' end,
 case when v_access_status='approved' then 'Your free course enrolment is active. Open your course and continue learning.'
 else 'Your admission has been accepted. Complete the course payment to activate learning access.' end,
 v_offer.application_id,p_offer_id,v_offer.course_id,v_now,'admission-accepted:'||p_offer_id::text,
 '/course.html?s='||(select slug from public.courses where id=v_offer.course_id))
 on conflict(dedupe_key) do nothing;
 if v_access_status='approved' then
   return jsonb_build_object('status','enrolled','message','Admission accepted. Your free course is now active — continue learning.');
 end if;
 return jsonb_build_object('status','approved_pending_payment','message','Admission accepted. Continue to your course payment portal to activate learning access.');
end $$;
revoke all on function public.accept_academy_admission_offer(uuid) from public,anon;
grant execute on function public.accept_academy_admission_offer(uuid) to authenticated;

create or replace function public.cv_payment_confirm_enrol()
returns trigger language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_app record;
begin
 if new.status='confirmed' and old.status is distinct from 'confirmed' then
   insert into public.enrolments(user_id,course_id) values(new.user_id,new.course_id)
   on conflict(user_id,course_id) do nothing;
   for v_app in select id,status from public.academy_applications
     where user_id=new.user_id and course_id=new.course_id and status='approved_pending_payment'
     order by created_at desc
   loop
     update public.academy_applications set status='approved',updated_at=now() where id=v_app.id;
     insert into public.academy_application_events(application_id,actor_id,event_type,from_status,to_status,message,metadata)
     values(v_app.id,null,'payment_confirmed','approved_pending_payment','approved',
       'Payment confirmed. Course access has been activated.',
       jsonb_build_object('payment_order_id',new.id,'confirmed_at',coalesce(new.confirmed_at,now())));
     insert into public.academy_notifications(user_id,notification_type,title,body,related_application_id,related_course_id,scheduled_for,dedupe_key,action_url)
     values(new.user_id,'payment_confirmed','Payment confirmed — course unlocked',
       'Your payment has been confirmed. Your Academy course is now available in your learning dashboard.',
       v_app.id,new.course_id,now(),'academy-payment-confirmed:'||new.id::text||':'||v_app.id::text,
       '/course.html?s='||(select slug from public.courses where id=new.course_id))
     on conflict(dedupe_key) do nothing;
   end loop;
 end if;
 return new;
end $$;

-- One-time reconciliation for accepted free offers already in production.
with accepted as (
 select o.application_id,o.user_id,o.course_id,o.accepted_at
 from public.academy_admission_offers o join public.courses c on c.id=o.course_id
 where o.status='accepted' and coalesce(c.price_ngn,0)<=0
)
insert into public.enrolments(user_id,course_id)
select user_id,course_id from accepted
on conflict(user_id,course_id) do nothing;

update public.academy_applications a set status='approved',
 offer_accepted_at=coalesce(a.offer_accepted_at,o.accepted_at,now()),updated_at=now()
from public.academy_admission_offers o join public.courses c on c.id=o.course_id
where o.application_id=a.id and o.status='accepted' and coalesce(c.price_ngn,0)<=0;

update public.academy_interview_invitations i set status='cancelled',published_at=null,updated_at=now()
from public.academy_admission_offers o
where o.application_id=i.application_id and o.status='accepted'
and i.status not in ('cancelled','declined');

update public.academy_interviews i set status='cancelled',updated_at=now()
from public.academy_admission_offers o
where o.application_id=i.application_id and o.status='accepted'
and i.status not in ('cancelled','declined','completed','submitted');

update public.academy_live_calls lc set status='cancelled',responded_at=now()
where lc.status='ringing' and exists(
 select 1 from public.academy_interviews i join public.academy_admission_offers o on o.application_id=i.application_id
 where i.id=lc.interview_id and o.status='accepted'
);

-- Enable authenticated, RLS-governed realtime updates for connected portal views.
do $$
declare t text;
begin
 foreach t in array array['academy_applications','academy_admission_offers','academy_interview_invitations','enrolments','payment_orders'] loop
   if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
     execute format('alter publication supabase_realtime add table public.%I',t);
   end if;
 end loop;
end $$;
