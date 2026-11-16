-- Shared, per-conversation chat appearance preferences across web and mobile.
create table if not exists public.cv_chat_preferences (
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.cv_conversations(id) on delete cascade,
  wallpaper_color text not null default '#09251b' check (wallpaper_color ~ '^#[0-9A-Fa-f]{6}$'),
  outgoing_bubble_color text not null default '#1b6545' check (outgoing_bubble_color ~ '^#[0-9A-Fa-f]{6}$'),
  updated_at timestamptz not null default now(),
  primary key(user_id,conversation_id)
);
alter table public.cv_chat_preferences enable row level security;
revoke all on public.cv_chat_preferences from anon,authenticated;
grant select,insert,update on public.cv_chat_preferences to authenticated;
drop policy if exists "chat preferences owner read" on public.cv_chat_preferences;
create policy "chat preferences owner read" on public.cv_chat_preferences for select to authenticated
using (user_id=(select auth.uid()) and exists(select 1 from public.cv_conversations c where c.id=conversation_id and (c.user_a=(select auth.uid()) or c.user_b=(select auth.uid()))));
drop policy if exists "chat preferences owner insert" on public.cv_chat_preferences;
create policy "chat preferences owner insert" on public.cv_chat_preferences for insert to authenticated
with check (user_id=(select auth.uid()) and exists(select 1 from public.cv_conversations c where c.id=conversation_id and (c.user_a=(select auth.uid()) or c.user_b=(select auth.uid()))));
drop policy if exists "chat preferences owner update" on public.cv_chat_preferences;
create policy "chat preferences owner update" on public.cv_chat_preferences for update to authenticated
using (user_id=(select auth.uid()) and exists(select 1 from public.cv_conversations c where c.id=conversation_id and (c.user_a=(select auth.uid()) or c.user_b=(select auth.uid()))))
with check (user_id=(select auth.uid()) and exists(select 1 from public.cv_conversations c where c.id=conversation_id and (c.user_a=(select auth.uid()) or c.user_b=(select auth.uid()))));
