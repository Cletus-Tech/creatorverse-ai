-- The action button works through its real destination URL.
-- Defer public click analytics until it can be recorded through a constrained event pipeline.
revoke all on function public.record_billboard_click(uuid) from public, anon, authenticated;
drop function if exists public.record_billboard_click(uuid);
