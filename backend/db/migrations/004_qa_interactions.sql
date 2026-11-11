-- Idempotent Q&A likes and replies.
-- Does not modify existing questions, attendee_profiles, polls or votes.
-- Apply in the Supabase SQL editor or: psql "$DATABASE_URL" -f db/migrations/004_qa_interactions.sql

CREATE TABLE IF NOT EXISTS public.question_likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (question_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.question_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 2 AND 240),
  author_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS question_likes_question_id_idx
  ON public.question_likes (question_id);

CREATE INDEX IF NOT EXISTS question_likes_user_id_idx
  ON public.question_likes (user_id);

CREATE INDEX IF NOT EXISTS question_replies_question_id_created_at_idx
  ON public.question_replies (question_id, created_at ASC);

ALTER TABLE public.question_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_replies ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.question_likes, public.question_replies
FROM PUBLIC, anon, authenticated;
