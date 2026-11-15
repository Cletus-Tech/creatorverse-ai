-- Respect existing community blocks in Marketplace private conversations.
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
  if exists(select 1 from public.community_blocks b
    where (b.blocker_id=v_user and b.blocked_id=v_seller_user)
       or (b.blocker_id=v_seller_user and b.blocked_id=v_user)) then
    raise exception 'This conversation is unavailable';
  end if;

  insert into public.marketplace_enquiries(listing_id,buyer_id,seller_id,status)
  values(p_listing_id,v_user,v_seller_id,'open')
  on conflict(listing_id,buyer_id) do update set status='open',updated_at=now()
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
  if exists(select 1 from public.community_blocks b
    where (b.blocker_id=v_buyer and b.blocked_id=v_seller_user)
       or (b.blocker_id=v_seller_user and b.blocked_id=v_buyer)) then
    raise exception 'This conversation is unavailable';
  end if;

  insert into public.marketplace_enquiry_messages(enquiry_id,sender_id,body)
  values(p_enquiry_id,v_user,v_body)
  returning id into v_message_id;
  return v_message_id;
end;
$$;
revoke all on function public.marketplace_send_enquiry_message(uuid,text) from public,anon;
grant execute on function public.marketplace_send_enquiry_message(uuid,text) to authenticated;
