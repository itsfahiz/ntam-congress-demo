-- 007: Allow saved speaker favorites alongside existing sessions and resources.
-- Apply to the existing Supabase project after 005_saved_items.sql.
-- Additive: preserves every saved row and existing attendee.
BEGIN;
ALTER TABLE public.saved_items
  DROP CONSTRAINT IF EXISTS saved_items_item_type_check;
ALTER TABLE public.saved_items
  ADD CONSTRAINT saved_items_item_type_check
  CHECK (item_type IN ('session', 'resource', 'speaker'));
COMMIT;
