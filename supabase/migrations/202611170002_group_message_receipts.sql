-- Per-recipient receipts for CreatorVerse messages.
-- Group reads must never update the shared cv_direct_messages.read_at field.

create table if not exists public.cv_message_receipts (
  message_id uuid not null references public.cv_direct_messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  delivered_at timestamptz,
  read_at timestamptz,
  primary key (message_id, user_id),
  constraint cv_message_receipts_read_requires_delivery
    check (read_at is null or delivered_at is not null)
);

create index if not exists cv_message_receipts_user_read_idx
  on public.cv_message_receipts(user_id, read_at);

alter table public.cv_message_receipts enable row level security;
revoke all on public.cv_message_receipts from anon;
grant select, insert, update on public.cv_message_receipts to authenticated;

drop policy if exists "CV members read message receipts" on public.cv_message_receipts;
create policy "CV members read message receipts"
on public.cv_message_receipts for select to authenticated
using (
  exists (
    select 1
    from public.cv_direct_messages m
    join public.cv_conversations c on c.id = m.conversation_id
    where m.id = cv_message_receipts.message_id
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "CV recipients create own message receipts" on public.cv_message_receipts;
create policy "CV recipients create own message receipts"
on public.cv_message_receipts for insert to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.cv_direct_messages m
    join public.cv_conversations c on c.id = m.conversation_id
    where m.id = cv_message_receipts.message_id
      and m.sender_id <> auth.uid()
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);

drop policy if exists "CV recipients update own message receipts" on public.cv_message_receipts;
create policy "CV recipients update own message receipts"
on public.cv_message_receipts for update to authenticated
using (
  user_id = auth.uid()
  and exists (
    select 1
    from public.cv_direct_messages m
    join public.cv_conversations c on c.id = m.conversation_id
    where m.id = cv_message_receipts.message_id
      and m.sender_id <> auth.uid()
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
)
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.cv_direct_messages m
    join public.cv_conversations c on c.id = m.conversation_id
    where m.id = cv_message_receipts.message_id
      and m.sender_id <> auth.uid()
      and (
        (not c.is_group and (auth.uid() = c.user_a or auth.uid() = c.user_b))
        or (c.is_group and private.cv_is_conversation_member(c.id))
      )
  )
);
