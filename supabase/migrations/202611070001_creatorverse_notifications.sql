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