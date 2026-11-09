-- Admin-controlled student announcements via the existing CreatorVerse notification centre.
create or replace function public.admin_broadcast_notification(
 p_title text,
 p_body text,
 p_href text default 'notifications.html',
 p_audience text default 'all_students',
 p_course_id uuid default null
) returns jsonb
language plpgsql security definer set search_path=pg_catalog,public
as $$
declare v_count integer:=0; v_href text;
begin
 if auth.uid() is null or not public.is_admin() then raise exception 'Only authorized administrators can send announcements'; end if;
 if length(btrim(coalesce(p_title,'')))<3 or length(btrim(p_title))>120 then raise exception 'Title must be between 3 and 120 characters'; end if;
 if length(btrim(coalesce(p_body,'')))<3 or length(btrim(p_body))>2000 then raise exception 'Message must be between 3 and 2000 characters'; end if;
 if p_audience not in ('all_students','course_students') then raise exception 'Choose a valid audience'; end if;
 if p_audience='course_students' and p_course_id is null then raise exception 'Choose a course for this audience'; end if;
 if p_audience='course_students' and not exists(select 1 from public.courses where id=p_course_id) then raise exception 'Selected course was not found'; end if;
 v_href:=coalesce(nullif(btrim(p_href),''),'notifications.html');
 if v_href ~* '^(https?:|javascript:|data:|//)' then raise exception 'Use an internal CreatorVerse page link only'; end if;
 if left(v_href,1)='/' then v_href:=substring(v_href from 2); end if;
 if p_audience='all_students' then
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type)
  select p.id,auth.uid(),'announcement',btrim(p_title),btrim(p_body),v_href,'announcement'
  from public.profiles p where p.role='student';
 else
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  select distinct e.user_id,auth.uid(),'announcement',btrim(p_title),btrim(p_body),v_href,'course',p_course_id
  from public.enrolments e join public.profiles p on p.id=e.user_id
  where e.course_id=p_course_id and p.role='student';
 end if;
 get diagnostics v_count=row_count;
 return jsonb_build_object('sent',v_count,'audience',p_audience);
end $$;
revoke all on function public.admin_broadcast_notification(text,text,text,text,uuid) from public,anon;
grant execute on function public.admin_broadcast_notification(text,text,text,text,uuid) to authenticated;
