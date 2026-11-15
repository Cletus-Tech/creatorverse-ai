-- Private buyer/seller enquiry threads for published Marketplace listings.
-- Messages are visible only to the buyer and seller participants; admins have no RLS read policy.
-- No checkout, payment, attachments or external contact disclosure is introduced.

create table if not exists public.marketplace_enquiries (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.marketplace_listings(id) on delete restrict,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references public.marketplace_sellers(id) on delete restrict,
  status text not null default 'open' check (status in ('open','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  unique (listing_id, buyer_id)
);
create index if not exists marketplace_enquiries_buyer_idx on public.marketplace_enquiries(buyer_id,last_message_at desc);
create index if not exists marketplace_enquiries_seller_idx on public.marketplace_enquiries(seller_id,last_message_at desc);

create table if not exists public.marketplace_enquiry_messages (
  id uuid primary key default gen_random_uuid(),
  enquiry_id uuid not null references public.marketplace_enquiries(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(trim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index if not exists marketplace_enquiry_messages_thread_idx
on public.marketplace_enquiry_messages(enquiry_id,created_at);

alter table public.marketplace_enquiries enable row level security;
alter table public.marketplace_enquiry_messages enable row level security;
grant select on public.marketplace_enquiries to authenticated;
grant select on public.marketplace_enquiry_messages to authenticated;

drop policy if exists "Marketplace enquiry participants read threads" on public.marketplace_enquiries;
create policy "Marketplace enquiry participants read threads"
on public.marketplace_enquiries for select to authenticated
using (
  buyer_id = (select auth.uid())
  or exists (
    select 1 from public.marketplace_sellers s
    where s.id = seller_id and s.user_id = (select auth.uid())
  )
);

drop policy if exists "Marketplace enquiry participants read messages" on public.marketplace_enquiry_messages;
create policy "Marketplace enquiry participants read messages"
on public.marketplace_enquiry_messages for select to authenticated
using (
  exists (
    select 1 from public.marketplace_enquiries e
    where e.id = enquiry_id
      and (
        e.buyer_id = (select auth.uid())
        or exists (
          select 1 from public.marketplace_sellers s
          where s.id = e.seller_id and s.user_id = (select auth.uid())
        )
      )
  )
);

create or replace function private.marketplace_enquiry_message_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_buyer uuid;
  v_seller_user uuid;
  v_recipient uuid;
  v_actor_name text;
  v_listing_title text;
begin
  select e.buyer_id, s.user_id, l.title
    into v_buyer, v_seller_user, v_listing_title
  from public.marketplace_enquiries e
  join public.marketplace_sellers s on s.id = e.seller_id
  join public.marketplace_listings l on l.id = e.listing_id
  where e.id = new.enquiry_id;

  if v_buyer is null or v_seller_user is null then
    raise exception 'Marketplace enquiry participants could not be resolved';
  end if;

  v_recipient := case when new.sender_id = v_buyer then v_seller_user
                      when new.sender_id = v_seller_user then v_buyer
                      else null end;
  if v_recipient is null then
    raise exception 'Only enquiry participants can send messages';
  end if;

  update public.marketplace_enquiries
  set last_message_at = new.created_at, updated_at = now()
  where id = new.enquiry_id;

  select coalesce(nullif(p.full_name,''), nullif(p.username,''), 'A Marketplace user')
    into v_actor_name
  from public.profiles p where p.id = new.sender_id;

  insert into public.cv_notifications(user_id,actor_id,type,title,body,href,entity_type,entity_id)
  values (
    v_recipient,
    new.sender_id,
    'marketplace_enquiry',
    coalesce(v_actor_name,'A Marketplace user') || ' sent an enquiry message',
    'Regarding: ' || left(coalesce(v_listing_title,'your Marketplace listing'),100),
    'marketplace-enquiries.html?id=' || new.enquiry_id::text,
    'marketplace_enquiry',
    new.enquiry_id
  );
  return new;
end;
$$;
revoke all on function private.marketplace_enquiry_message_after_insert() from public, anon, authenticated;
drop trigger if exists marketplace_enquiry_message_after_insert on public.marketplace_enquiry_messages;
create trigger marketplace_enquiry_message_after_insert
after insert on public.marketplace_enquiry_messages
for each row execute function private.marketplace_enquiry_message_after_insert();

create or replace function public.marketplace_start_enquiry(p_listing_id uuid, p_message text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_seller_id uuid;
  v_seller_user uuid;
  v_enquiry_id uuid;
  v_body text := trim(coalesce(p_message,''));
begin
  if v_user is null then raise exception 'Please sign in to contact this seller'; end if;
  if char_length(v_body) < 5 or char_length(v_body) > 2000 then
    raise exception 'Your message must be between 5 and 2000 characters';
  end if;

  select l.seller_id, s.user_id
    into v_seller_id, v_seller_user
  from public.marketplace_listings l
  join public.marketplace_sellers s on s.id = l.seller_id
  where l.id = p_listing_id and l.status = 'published' and s.status = 'verified';

  if v_seller_id is null then raise exception 'This listing is no longer available'; end if;
  if v_seller_user = v_user then raise exception 'You cannot enquire about your own listing'; end if;

  insert into public.marketplace_enquiries(listing_id,buyer_id,seller_id,status)
  values(p_listing_id,v_user,v_seller_id,'open')
  on conflict(listing_id,buyer_id) do update
    set status='open',updated_at=now()
  returning id into v_enquiry_id;

  insert into public.marketplace_enquiry_messages(enquiry_id,sender_id,body)
  values(v_enquiry_id,v_user,v_body);
  return v_enquiry_id;
end;
$$;
revoke all on function public.marketplace_start_enquiry(uuid,text) from public,anon;
grant execute on function public.marketplace_start_enquiry(uuid,text) to authenticated;

create or replace function public.marketplace_send_enquiry_message(p_enquiry_id uuid, p_message text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_buyer uuid;
  v_seller_user uuid;
  v_message_id uuid;
  v_body text := trim(coalesce(p_message,''));
begin
  if v_user is null then raise exception 'Please sign in first'; end if;
  if char_length(v_body) < 1 or char_length(v_body) > 2000 then
    raise exception 'Your message must be between 1 and 2000 characters';
  end if;

  select e.buyer_id,s.user_id into v_buyer,v_seller_user
  from public.marketplace_enquiries e
  join public.marketplace_sellers s on s.id=e.seller_id
  where e.id=p_enquiry_id and e.status='open';

  if v_buyer is null or v_user not in (v_buyer,v_seller_user) then
    raise exception 'This enquiry is unavailable or closed';
  end if;

  insert into public.marketplace_enquiry_messages(enquiry_id,sender_id,body)
  values(p_enquiry_id,v_user,v_body)
  returning id into v_message_id;
  return v_message_id;
end;
$$;
revoke all on function public.marketplace_send_enquiry_message(uuid,text) from public,anon;
grant execute on function public.marketplace_send_enquiry_message(uuid,text) to authenticated;

create or replace function public.marketplace_mark_enquiry_read(p_enquiry_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_buyer uuid;
  v_seller_user uuid;
  v_count integer;
begin
  if v_user is null then raise exception 'Please sign in first'; end if;
  select e.buyer_id,s.user_id into v_buyer,v_seller_user
  from public.marketplace_enquiries e
  join public.marketplace_sellers s on s.id=e.seller_id
  where e.id=p_enquiry_id;
  if v_user not in (v_buyer,v_seller_user) or v_buyer is null then
    raise exception 'Enquiry not found';
  end if;

  update public.marketplace_enquiry_messages
  set read_at=now()
  where enquiry_id=p_enquiry_id and sender_id<>v_user and read_at is null;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.marketplace_mark_enquiry_read(uuid) from public,anon;
grant execute on function public.marketplace_mark_enquiry_read(uuid) to authenticated;

create or replace function public.marketplace_close_enquiry(p_enquiry_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_buyer uuid;
  v_seller_user uuid;
begin
  if v_user is null then raise exception 'Please sign in first'; end if;
  select e.buyer_id,s.user_id into v_buyer,v_seller_user
  from public.marketplace_enquiries e
  join public.marketplace_sellers s on s.id=e.seller_id
  where e.id=p_enquiry_id;
  if v_user not in (v_buyer,v_seller_user) or v_buyer is null then
    raise exception 'Enquiry not found';
  end if;
  update public.marketplace_enquiries set status='closed',updated_at=now()
  where id=p_enquiry_id and status='open';
  return found;
end;
$$;
revoke all on function public.marketplace_close_enquiry(uuid) from public,anon;
grant execute on function public.marketplace_close_enquiry(uuid) to authenticated;

do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='marketplace_enquiries') then
      alter publication supabase_realtime add table public.marketplace_enquiries;
    end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='marketplace_enquiry_messages') then
      alter publication supabase_realtime add table public.marketplace_enquiry_messages;
    end if;
  end if;
end $$;
