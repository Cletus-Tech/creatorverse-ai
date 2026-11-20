alter table public.billboard_items
  add column if not exists target_audience text not null default 'whole_platform',
  add column if not exists send_notification boolean not null default false;

alter table public.billboard_items
  drop constraint if exists billboard_items_target_audience_check,
  add constraint billboard_items_target_audience_check
  check (target_audience in ('whole_platform','students','creators','administrators'));

create or replace function public.notify_billboard_audience(p_billboard_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item public.billboard_items%rowtype;
  v_count integer := 0;
begin
  if not public.is_admin() then
    raise exception 'Administrator access required';
  end if;

  select * into v_item
  from public.billboard_items
  where id = p_billboard_id and is_published = true;

  if not found then
    raise exception 'Published billboard announcement not found';
  end if;

  with recipients as (
    select p.id
    from public.profiles p
    where
      v_item.target_audience = 'whole_platform'
      or (v_item.target_audience = 'students' and p.role = 'student')
      or (v_item.target_audience = 'creators' and p.role = 'creator')
      or (v_item.target_audience = 'administrators' and p.role in ('admin','super_admin'))
  ), updated as (
    update public.cv_notifications n
    set title = v_item.title,
        body = nullif(v_item.message,''),
        created_at = now(),
        read_at = null,
        category = 'announcements',
        priority = 'normal',
        expires_at = v_item.ends_at
    from recipients r
    where n.user_id = r.id
      and n.entity_type = 'billboard'
      and n.entity_id = v_item.id
    returning n.id
  ), inserted as (
    insert into public.cv_notifications
      (user_id, actor_id, type, title, body, href, entity_type, entity_id, category, priority, expires_at)
    select r.id, auth.uid(), 'system', v_item.title, nullif(v_item.message,''), 'notifications.html',
           'billboard', v_item.id, 'announcements', 'normal', v_item.ends_at
    from recipients r
    where not exists (
      select 1 from public.cv_notifications n
      where n.user_id = r.id and n.entity_type = 'billboard' and n.entity_id = v_item.id
    )
    returning id
  )
  select (select count(*) from updated) + (select count(*) from inserted)
  into v_count;

  return v_count;
end;
$$;

revoke all on function public.notify_billboard_audience(uuid) from public;
grant execute on function public.notify_billboard_audience(uuid) to authenticated;
