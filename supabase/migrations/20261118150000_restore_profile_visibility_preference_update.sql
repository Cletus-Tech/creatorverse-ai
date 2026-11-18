-- Allow users to update their own avatar visibility preference.
-- The existing "update own profile" RLS policy still restricts updates
-- to the authenticated user's own profile row (auth.uid() = id).
grant update (avatar_is_public)
  on table public.profiles to authenticated;
