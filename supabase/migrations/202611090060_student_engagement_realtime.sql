do $$
begin
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='academy_learning_activity') then
    alter publication supabase_realtime add table public.academy_learning_activity;
  end if;
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='lesson_progress') then
    alter publication supabase_realtime add table public.lesson_progress;
  end if;
end $$;