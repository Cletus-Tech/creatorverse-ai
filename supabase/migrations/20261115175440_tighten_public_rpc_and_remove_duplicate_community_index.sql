-- Tighten public RPC exposure for helper functions that only make sense for signed-in users.
-- Keep verify_certificate public because the certificate verification page is intentionally public.
revoke execute on function public.cv_is_content_admin() from public, anon;
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_enrolled(uuid) from public, anon;
revoke execute on function public.is_super_admin() from public, anon;

grant execute on function public.cv_is_content_admin() to authenticated, service_role;
grant execute on function public.is_admin() to authenticated, service_role;
grant execute on function public.is_enrolled(uuid) to authenticated, service_role;
grant execute on function public.is_super_admin() to authenticated, service_role;

-- The following two indexes had identical definitions on community_comments(post_id, created_at).
drop index if exists public.community_comments_post_idx;
