-- Draft-only CreatorVerse educator curriculum CMS.
-- Repository draft: do not apply to production until explicitly approved.
create or replace function public.cv_is_content_admin()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('admin','super_admin'));
$$;
revoke all on function public.cv_is_content_admin() from public;
grant execute on function public.cv_is_content_admin() to authenticated;

create table if not exists public.cv_curriculum_items (
 id uuid primary key default gen_random_uuid(),
 course_id uuid references public.courses(id) on delete set null,
 parent_id uuid references public.cv_curriculum_items(id) on delete set null,
 item_type text not null check(item_type in ('course','stage','lesson','resource','assessment')),
 title text not null, slug text, summary text,
 content_md text not null default '',
 learning_outcomes jsonb not null default '[]'::jsonb,
 metadata jsonb not null default '{}'::jsonb,
 status text not null default 'draft' check(status in ('draft','review','approved','archived')),
 position integer not null default 1, estimated_minutes integer,
 deleted_at timestamptz,
 created_by uuid references auth.users(id) on delete set null,
 updated_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint cv_curriculum_parent_type check((item_type='course' and parent_id is null) or (item_type<>'course' and parent_id is not null))
);
create index if not exists cv_curriculum_course_idx on public.cv_curriculum_items(course_id,position);
create index if not exists cv_curriculum_parent_idx on public.cv_curriculum_items(parent_id,position);
create index if not exists cv_curriculum_status_idx on public.cv_curriculum_items(status) where deleted_at is null;

create table if not exists public.cv_curriculum_revisions (
 id bigint generated always as identity primary key,
 item_id uuid not null, action text not null check(action in ('insert','update','archive','restore','delete')),
 before_data jsonb, after_data jsonb, actor_id uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now()
);
create index if not exists cv_curriculum_revisions_item_idx on public.cv_curriculum_revisions(item_id,created_at desc);
alter table public.cv_curriculum_items enable row level security;
alter table public.cv_curriculum_revisions enable row level security;
drop policy if exists cv_curriculum_admin_all on public.cv_curriculum_items;
create policy cv_curriculum_admin_all on public.cv_curriculum_items for all to authenticated using(public.cv_is_content_admin()) with check(public.cv_is_content_admin());
drop policy if exists cv_curriculum_revisions_admin_read on public.cv_curriculum_revisions;
create policy cv_curriculum_revisions_admin_read on public.cv_curriculum_revisions for select to authenticated using(public.cv_is_content_admin());
drop policy if exists cv_curriculum_revisions_admin_insert on public.cv_curriculum_revisions;
create policy cv_curriculum_revisions_admin_insert on public.cv_curriculum_revisions for insert to authenticated with check(public.cv_is_content_admin() and actor_id=auth.uid());

create or replace function public.cv_log_curriculum_revision()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_action text; v_before jsonb; v_after jsonb; v_id uuid;
begin
 if tg_op='INSERT' then v_action:='insert';v_after:=to_jsonb(new);v_id:=new.id;new.created_by:=coalesce(new.created_by,auth.uid());new.updated_by:=auth.uid();new.updated_at:=now();
 elsif tg_op='UPDATE' then v_before:=to_jsonb(old);v_after:=to_jsonb(new);v_id:=new.id;
  v_action:=case when old.deleted_at is not null and new.deleted_at is null then 'restore' when old.status<>'archived' and new.status='archived' then 'archive' else 'update' end;
  new.updated_by:=auth.uid();new.updated_at:=now();
 else v_action:='delete';v_before:=to_jsonb(old);v_id:=old.id;end if;
 insert into public.cv_curriculum_revisions(item_id,action,before_data,after_data,actor_id) values(v_id,v_action,v_before,v_after,auth.uid());
 if tg_op='DELETE' then return old;end if;return new;
end $$;
drop trigger if exists cv_curriculum_revision_trigger on public.cv_curriculum_items;
create trigger cv_curriculum_revision_trigger before insert or update or delete on public.cv_curriculum_items for each row execute function public.cv_log_curriculum_revision();
grant select,insert,update,delete on public.cv_curriculum_items to authenticated;
grant select on public.cv_curriculum_revisions to authenticated;
grant usage,select on sequence public.cv_curriculum_revisions_id_seq to authenticated;
