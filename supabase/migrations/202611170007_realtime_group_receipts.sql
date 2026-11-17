-- Publish per-member message receipts for live group read indicators.
alter publication supabase_realtime add table public.cv_message_receipts;
