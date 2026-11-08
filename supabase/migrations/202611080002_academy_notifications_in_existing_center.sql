-- Academy notifications are read alongside CreatorVerse social notifications
-- by the existing notification centre. Keep scheduled_for semantics intact:
-- future reminders must not be shown before they are due.
drop trigger if exists academy_notification_to_cv on public.academy_notifications;
drop function if exists public.mirror_academy_notification_to_creatorverse();