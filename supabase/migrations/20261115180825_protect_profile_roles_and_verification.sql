-- Protect privileged profile fields from direct client updates.
revoke update on table public.profiles from public, anon, authenticated;
grant update (full_name, email, avatar_url, username, bio, cover_url, location, website_url, skills, status_text, updated_at)
  on table public.profiles to authenticated;

-- Role and verification changes are performed through a narrowly scoped super-admin RPC.
create or replace function public.admin_set_profile_access(
  p_user_id uuid,
  p_role text default null,
  p_verified_badge text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_role text;
  v_badge text;
begin
  if auth.uid() is null or not public.is_super_admin() then
    raise exception 'Only a super administrator can change account roles or verification badges';
  end if;

  if p_user_id is null or p_user_id = auth.uid() then
    raise exception 'You cannot change your own privileged account settings';
  end if;

  if p_role is null and p_verified_badge is null then
    raise exception 'No account access change was supplied';
  end if;

  if p_role is not null and p_role not in ('student','creator','instructor','moderator','admin','super_admin') then
    raise exception 'Invalid CreatorVerse account role';
  end if;

  if p_verified_badge is not null and p_verified_badge not in ('none','blue') then
    raise exception 'Invalid verification badge';
  end if;

  update public.profiles
  set role = coalesce(p_role, role),
      verified_badge = coalesce(p_verified_badge, verified_badge),
      updated_at = now()
  where id = p_user_id
  returning role, verified_badge into v_role, v_badge;

  if not found then
    raise exception 'Profile not found';
  end if;

  return jsonb_build_object('user_id',p_user_id,'role',v_role,'verified_badge',v_badge);
end;
$function$;

revoke execute on function public.admin_set_profile_access(uuid,text,text) from public, anon;
grant execute on function public.admin_set_profile_access(uuid,text,text) to authenticated;
