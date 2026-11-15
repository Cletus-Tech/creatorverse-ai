-- Trigger functions are implementation details, not client-callable RPC endpoints.
-- PostgreSQL invokes trigger functions through their attached triggers after creation;
-- clients do not need EXECUTE privileges on them.
revoke all on function public.marketplace_guard_seller() from public, anon, authenticated;
revoke all on function public.marketplace_guard_listing() from public, anon, authenticated;
