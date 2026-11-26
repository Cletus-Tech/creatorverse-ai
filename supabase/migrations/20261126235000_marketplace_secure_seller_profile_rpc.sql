create or replace function public.marketplace_get_my_seller_profile()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user uuid := auth.uid();
  v_profile jsonb;
begin
  if v_user is null then
    raise exception 'Sign in to access your seller profile';
  end if;

  select jsonb_build_object(
    'id', s.id,
    'user_id', s.user_id,
    'display_name', s.display_name,
    'seller_type', s.seller_type,
    'institution', s.institution,
    'campus', s.campus,
    'bio', s.bio,
    'status', s.status,
    'review_note', s.review_note,
    'created_at', s.created_at
  )
  into v_profile
  from public.marketplace_sellers s
  where s.user_id = v_user;

  return v_profile;
end;
$function$;

revoke all on function public.marketplace_get_my_seller_profile() from public, anon;
grant execute on function public.marketplace_get_my_seller_profile() to authenticated;
