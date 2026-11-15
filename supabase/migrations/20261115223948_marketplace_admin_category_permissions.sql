-- Marketplace administrator category controls.
-- Reuse the existing public.is_admin() authorization helper and RLS policy
-- created by 202611130010_marketplace_seller_and_listing_foundation.sql.
grant update on public.marketplace_categories to authenticated;
