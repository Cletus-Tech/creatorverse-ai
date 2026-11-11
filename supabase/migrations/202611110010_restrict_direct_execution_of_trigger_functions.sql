-- Restrict trigger-only SECURITY DEFINER functions from direct PostgREST/RPC invocation.
REVOKE EXECUTE ON FUNCTION public.cv_capture_content_revision() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.cv_log_division_revision() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_academy_interview_status() FROM PUBLIC, anon, authenticated;

ALTER FUNCTION public.cv_capture_content_revision() SET search_path = pg_catalog, public;
ALTER FUNCTION public.cv_log_division_revision() SET search_path = pg_catalog, public;
