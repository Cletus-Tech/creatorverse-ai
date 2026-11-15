-- These Academy tables are accessed only through guarded SECURITY DEFINER RPCs.
-- Keep direct Data API access closed to anonymous and authenticated clients.
revoke all on table
  public.academy_engagement_alert_state,
  public.academy_engagement_policies,
  public.academy_learning_checkins,
  public.academy_learning_sessions,
  public.academy_student_admin_actions,
  public.academy_student_interventions
from public, anon, authenticated;
