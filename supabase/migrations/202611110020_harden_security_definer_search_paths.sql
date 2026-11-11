-- Harden SECURITY DEFINER routines against object-shadowing through search_path.
-- All referenced application objects are schema-qualified or intentionally resolve in public.
ALTER FUNCTION public.admin_get_engagement_overview() SET search_path = pg_catalog, public;
ALTER FUNCTION public.admin_set_course_engagement_policy(uuid, integer, integer) SET search_path = pg_catalog, public;
ALTER FUNCTION public.cv_is_content_admin() SET search_path = pg_catalog, public;
ALTER FUNCTION public.cv_restore_content_revision(bigint) SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_quiz(uuid) SET search_path = pg_catalog, public;
ALTER FUNCTION public.handle_new_user() SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_admin() SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_enrolled(uuid) SET search_path = pg_catalog, public;
ALTER FUNCTION public.is_super_admin() SET search_path = pg_catalog, public;
ALTER FUNCTION public.submit_quiz(uuid, jsonb) SET search_path = pg_catalog, public;
ALTER FUNCTION public.verify_certificate(text) SET search_path = pg_catalog, public;
