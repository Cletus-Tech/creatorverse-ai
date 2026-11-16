-- Rotate the exposed webhook credential and keep it encrypted in Supabase Vault.
do $$
begin
  if not exists (
    select 1 from vault.decrypted_secrets
    where name='CREATORVERSE_PUSH_WEBHOOK_SECRET'
  ) then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'CREATORVERSE_PUSH_WEBHOOK_SECRET',
      'Authentication secret for the CreatorVerse notification push webhook'
    );
  end if;
end
$$;

-- Only the Edge Function service role may retrieve the secret.
create or replace function public.cv_get_push_webhook_secret()
returns text language sql security definer set search_path = '' as $$
  select decrypted_secret from vault.decrypted_secrets
  where name='CREATORVERSE_PUSH_WEBHOOK_SECRET' limit 1
$$;
revoke all on function public.cv_get_push_webhook_secret() from public,anon,authenticated;
grant execute on function public.cv_get_push_webhook_secret() to service_role;

-- The trigger reads the encrypted secret from Vault; no literal credential is
-- stored in trigger arguments or migration source.
create or replace function private.cv_push_notification_webhook()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_secret text;
begin
  select decrypted_secret into v_secret from vault.decrypted_secrets
  where name='CREATORVERSE_PUSH_WEBHOOK_SECRET' limit 1;
  if v_secret is null then
    raise exception 'CreatorVerse push webhook secret is not configured in Vault';
  end if;
  perform net.http_post(
    'https://xgdngnekihhnkzurhvpe.supabase.co/functions/v1/creatorverse-push',
    jsonb_build_object('record',to_jsonb(new),'type',tg_op,'table',tg_table_name,'schema',tg_table_schema),
    '{}'::jsonb,
    jsonb_build_object('Content-Type','application/json','x-push-webhook-secret',v_secret),
    5000
  );
  return new;
end
$$;
revoke all on function private.cv_push_notification_webhook() from public,anon,authenticated;
drop trigger if exists creatorverse_push_on_notification on public.cv_notifications;
create trigger creatorverse_push_on_notification after insert on public.cv_notifications
for each row execute function private.cv_push_notification_webhook();
