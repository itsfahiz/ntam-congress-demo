-- Saved congress sessions and resources are stored per authenticated attendee.
-- Apply AFTER 004_qa_interactions.sql, before deploying the Saved API.
-- No existing tables or user data are modified.
CREATE TABLE IF NOT EXISTS public.saved_items (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type text NOT NULL CHECK (item_type IN ('session', 'resource')),
  item_id text NOT NULL CHECK (char_length(item_id) BETWEEN 1 AND 80),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, item_type, item_id)
);
CREATE INDEX IF NOT EXISTS saved_items_user_created_idx
  ON public.saved_items (user_id, created_at DESC);
-- The existing Express database connection is the only application writer.
-- Supabase client roles must not read or mutate another attendee's bookmarks.
ALTER TABLE public.saved_items ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.saved_items FROM PUBLIC, anon, authenticated;
