-- Keep Academy notifications available to all authenticated clients through Supabase Realtime.
-- The table already has per-user SELECT/UPDATE RLS policies.
do $$
begin
  if exists (select 1 from pg_publication where pubname='supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname='supabase_realtime'
         and schemaname='public'
         and tablename='academy_notifications'
     ) then
    alter publication supabase_realtime add table public.academy_notifications;
  end if;
end
$$;
