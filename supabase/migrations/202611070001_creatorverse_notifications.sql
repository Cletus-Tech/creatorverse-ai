create table if not exists public.cv_notifications(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,actor_id uuid references auth.users(id) on delete set null,type text not null default 'system',title text not null,body text,href text not null default 'notifications.html',entity_type text,entity_id uuid,created_at timestamptz not null default now(),read_at timestamptz);
create index if not exists cv_notifications_user_created_idx on public.cv_notifications(user_id,created_at desc);
create index if not exists cv_notifications_unread_idx on public.cv_notifications(user_id) where read_at is null;
alter table public.cv_notifications enable row level security;
grant select,update on public.cv_notifications to authenticated;
drop policy if exists "Users read own notifications" on public.cv_notifications;
create policy "Users read own notifications" on public.cv_notifications for select to authenticated using((select auth.uid())=user_id);
drop policy if exists "Users update own notifications" on public.cv_notifications;
create policy "Users update own notifications" on public.cv_notifications for update to authenticated using((select auth.uid())=user_id) with check((select auth.uid())=user_id);
create schema if not exists private;
revoke all on schema private from public,anon,authenticated;
create or replace function private.cv_notify_direct_message() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare recipient uuid; sender_name text; preview text;
begin
select case when c.user_a=new.sender_id then c.user_b else c.user_a end into recipient from public.cv_conversations c where c.id=new.conversation_id and (c.user_a=new.sender_id or c.user_b=new.sender_id);
if recipient is null or recipient=new.sender_id then return new; end if;
select coalesce(nullif(p.full_name,''),nullif(p.username,''),'Someone') into sender_name from public.profiles p where p.id=new.sender_id;
preview:=case when new.attachment_path is not null then 'Sent you an attachment' else left(coalesce(new.body,'Sent you a message'),140) end;
insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id) values(recipient,new.sender_id,'message',coalesce(sender_name,'Someone')||' sent you a message',preview,'messages.html','conversation',new.conversation_id);
return new; end $$;
revoke all on function private.cv_notify_direct_message() from public,anon,authenticated;
drop trigger if exists cv_notify_on_direct_message on public.cv_direct_messages;
create trigger cv_notify_on_direct_message after insert on public.cv_direct_messages for each row execute function private.cv_notify_direct_message();
do $$ begin if exists(select 1 from pg_publication where pubname='supabase_realtime') and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='cv_notifications') then alter publication supabase_realtime add table public.cv_notifications; end if; end $$;

-- Social activity notification triggers (follows, post likes, post comments)
create or replace function private.cv_notify_new_follower()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare actor_name text; actor_key text;
begin
 if new.follower_id=new.following_id then return new; end if;
 select coalesce(nullif(full_name,''),nullif(username,''),'Someone'),coalesce(nullif(username,''),id::text) into actor_name,actor_key from public.profiles where id=new.follower_id;
 insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id) values(new.following_id,new.follower_id,'follow',coalesce(actor_name,'Someone')||' started following you','Visit their creator profile','profile.html?u='||actor_key,'profile',new.follower_id);
 return new; end $$;
revoke all on function private.cv_notify_new_follower() from public,anon,authenticated;
drop trigger if exists cv_notify_on_new_follower on public.community_follows;
create trigger cv_notify_on_new_follower after insert on public.community_follows for each row execute function private.cv_notify_new_follower();
create or replace function private.cv_notify_post_like()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare recipient uuid; actor_name text;
begin select user_id into recipient from public.community_posts where id=new.post_id;
if recipient is null or recipient=new.user_id then return new; end if;
select coalesce(nullif(full_name,''),nullif(username,''),'Someone') into actor_name from public.profiles where id=new.user_id;
insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id) values(recipient,new.user_id,'like',coalesce(actor_name,'Someone')||' liked your post','Someone appreciated your community post','community.html','post',new.post_id); return new; end $$;
revoke all on function private.cv_notify_post_like() from public,anon,authenticated;
drop trigger if exists cv_notify_on_post_like on public.community_likes;
create trigger cv_notify_on_post_like after insert on public.community_likes for each row execute function private.cv_notify_post_like();
create or replace function private.cv_notify_post_comment()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare recipient uuid; actor_name text; preview text;
begin select user_id into recipient from public.community_posts where id=new.post_id;
if recipient is null or recipient=new.user_id then return new; end if;
select coalesce(nullif(full_name,''),nullif(username,''),'Someone') into actor_name from public.profiles where id=new.user_id;
preview:=left(coalesce(new.body,'Commented on your post'),120);
insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id) values(recipient,new.user_id,'comment',coalesce(actor_name,'Someone')||' commented on your post',preview,'community.html','post',new.post_id); return new; end $$;
revoke all on function private.cv_notify_post_comment() from public,anon,authenticated;
drop trigger if exists cv_notify_on_post_comment on public.community_comments;
create trigger cv_notify_on_post_comment after insert on public.community_comments for each row execute function private.cv_notify_post_comment();
