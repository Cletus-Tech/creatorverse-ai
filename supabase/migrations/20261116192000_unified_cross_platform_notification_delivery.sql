-- Make cv_notifications the single delivery stream for Android and website alerts.
-- Academy rows keep their own workflow table, but are mirrored only when due.
-- Community activity is mirrored from its existing notification table.

create extension if not exists pg_cron with schema pg_catalog;

create or replace function private.cv_mirror_academy_notification()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_entity_id uuid;
begin
  v_entity_id := coalesce(new.related_application_id,new.related_offer_id,new.related_interview_id,new.related_course_id);
  if tg_op='INSERT' then
    if new.scheduled_for<=now() then
      insert into public.cv_notifications(id,user_id,actor_id,type,title,body,href,entity_type,entity_id,created_at,read_at)
      values(new.id,new.user_id,null,new.notification_type,new.title,new.body,
        coalesce(nullif(new.action_url,''),'academy-status.html'),'academy_notification',v_entity_id,
        greatest(new.created_at,new.scheduled_for),new.read_at)
      on conflict(id) do nothing;
    end if;
  elsif old.read_at is distinct from new.read_at then
    update public.cv_notifications set read_at=new.read_at
    where id=new.id and user_id=new.user_id and read_at is distinct from new.read_at;
  end if;
  return new;
end $$;
revoke all on function private.cv_mirror_academy_notification() from public,anon,authenticated;
drop trigger if exists cv_mirror_academy_notification on public.academy_notifications;
create trigger cv_mirror_academy_notification after insert or update of read_at
on public.academy_notifications for each row execute function private.cv_mirror_academy_notification();

create or replace function private.cv_mirror_community_notification()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_actor_name text; v_actor_key text; v_title text; v_href text; v_entity_id uuid;
begin
  if tg_op='INSERT' then
    select coalesce(nullif(p.full_name,''),nullif(p.username,''),'Someone'),
           coalesce(nullif(p.username,''),p.id::text)
    into v_actor_name,v_actor_key from public.profiles p where p.id=new.actor_id;
    v_title:=case new.type
      when 'follow' then coalesce(v_actor_name,'Someone')||' started following you'
      when 'like' then coalesce(v_actor_name,'Someone')||' liked your post'
      when 'reply' then coalesce(v_actor_name,'Someone')||' replied to your comment'
      else coalesce(v_actor_name,'Someone')||' commented on your post' end;
    v_href:=case when new.type='follow' then 'profile.html?u='||coalesce(v_actor_key,new.actor_id::text) else 'community.html' end;
    v_entity_id:=case when new.type='follow' then new.actor_id else coalesce(new.comment_id,new.post_id) end;
    insert into public.cv_notifications(id,user_id,actor_id,type,title,body,href,entity_type,entity_id,created_at,read_at)
    values(new.id,new.recipient_id,new.actor_id,'community_'||new.type,v_title,
      coalesce(new.message,'There is new community activity.'),v_href,'community_notification',
      v_entity_id,new.created_at,case when new.is_read then new.created_at else null end)
    on conflict(id) do nothing;
  elsif old.is_read is distinct from new.is_read then
    update public.cv_notifications set read_at=case when new.is_read then new.created_at else null end
    where id=new.id and user_id=new.recipient_id
      and read_at is distinct from case when new.is_read then new.created_at else null end;
  end if;
  return new;
end $$;
revoke all on function private.cv_mirror_community_notification() from public,anon,authenticated;
drop trigger if exists cv_mirror_community_notification on public.community_notifications;
create trigger cv_mirror_community_notification after insert or update of is_read
on public.community_notifications for each row execute function private.cv_mirror_community_notification();

create or replace function private.cv_sync_notification_read_state()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
begin
  if old.read_at is not distinct from new.read_at then return new; end if;
  if new.entity_type='academy_notification' then
    update public.academy_notifications set read_at=new.read_at
    where id=new.id and user_id=new.user_id and read_at is distinct from new.read_at;
  elsif new.entity_type='community_notification' then
    update public.community_notifications set is_read=(new.read_at is not null)
    where id=new.id and recipient_id=new.user_id and is_read is distinct from (new.read_at is not null);
  end if;
  return new;
end $$;
revoke all on function private.cv_sync_notification_read_state() from public,anon,authenticated;
drop trigger if exists cv_sync_notification_read_state on public.cv_notifications;
create trigger cv_sync_notification_read_state after update of read_at
on public.cv_notifications for each row execute function private.cv_sync_notification_read_state();

-- The existing community notification triggers now feed the shared stream.
drop trigger if exists cv_notify_on_new_follower on public.community_follows;
drop trigger if exists cv_notify_on_post_like on public.community_likes;
drop trigger if exists cv_notify_on_post_comment on public.community_comments;

create or replace function private.cv_notify_followers_new_community_post()
returns trigger language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_actor_name text;
begin
  if new.status is distinct from 'published' then return new; end if;
  if tg_op='UPDATE' and old.status='published' then return new; end if;
  select coalesce(nullif(full_name,''),nullif(username,''),'Someone')
    into v_actor_name from public.profiles where id=new.user_id;
  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  select f.follower_id,new.user_id,'community_post',
    coalesce(v_actor_name,'Someone')||' shared a new community post',
    left(coalesce(nullif(new.title,''),nullif(new.description,''),'Open Community to view the post.'),180),
    'community.html','community_post',new.id
  from public.community_follows f
  where f.following_id=new.user_id and f.follower_id<>new.user_id;
  return new;
end $$;
revoke all on function private.cv_notify_followers_new_community_post() from public,anon,authenticated;
drop trigger if exists cv_notify_followers_on_community_post on public.community_posts;
create trigger cv_notify_followers_on_community_post after insert or update of status
on public.community_posts for each row execute function private.cv_notify_followers_new_community_post();

-- Dispatch scheduled Academy reminders at their due time, not when they are first created.
create or replace function private.cv_dispatch_due_academy_notifications()
returns integer language plpgsql security definer set search_path = pg_catalog, public as $$
declare v_count integer:=0;
begin
  insert into public.cv_notifications(id,user_id,actor_id,type,title,body,href,entity_type,entity_id,created_at,read_at)
  select a.id,a.user_id,null,a.notification_type,a.title,a.body,
    coalesce(nullif(a.action_url,''),'academy-status.html'),'academy_notification',
    coalesce(a.related_application_id,a.related_offer_id,a.related_interview_id,a.related_course_id),
    greatest(a.created_at,a.scheduled_for),a.read_at
  from public.academy_notifications a
  where a.scheduled_for<=now()
    and not exists(select 1 from public.cv_notifications c where c.id=a.id)
  on conflict(id) do nothing;
  get diagnostics v_count=row_count;
  return v_count;
end $$;
revoke all on function private.cv_dispatch_due_academy_notifications() from public,anon,authenticated;
do $$
declare v_job bigint;
begin
  for v_job in select jobid from cron.job where jobname='cv-dispatch-due-academy-notifications'
  loop perform cron.unschedule(v_job); end loop;
  perform cron.schedule('cv-dispatch-due-academy-notifications','* * * * *',
    'select private.cv_dispatch_due_academy_notifications();');
end $$;
