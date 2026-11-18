-- Keep unanswered calls from remaining active when the caller app is closed.
-- The existing 45-second expiry is already stored on each call; this worker
-- applies the same expiry server-side and fires the missed-call chat trigger.
do $$
declare
  existing_job bigint;
begin
  select jobid into existing_job
  from cron.job
  where jobname = 'creatorverse-expire-stale-calls'
  limit 1;

  if existing_job is not null then
    perform cron.unschedule(existing_job);
  end if;

  perform cron.schedule(
    'creatorverse-expire-stale-calls',
    '* * * * *',
    'select private.cv_expire_stale_call_invites();'
  );
end;
$$;
