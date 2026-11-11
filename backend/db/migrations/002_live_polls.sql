-- Repeatable NTAM Congress live polling.
-- Apply in the Supabase SQL editor or: psql "$DATABASE_URL" -f db/migrations/002_live_polls.sql
-- Does not alter attendee_profiles or questions.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.polls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question text NOT NULL CHECK (char_length(btrim(question)) BETWEEN 8 AND 240),
  topic_label text NOT NULL DEFAULT 'Live poll',
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.poll_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES public.polls (id) ON DELETE CASCADE,
  label text NOT NULL CHECK (char_length(btrim(label)) BETWEEN 2 AND 80),
  sort_order integer NOT NULL,
  UNIQUE (poll_id, sort_order)
);

CREATE UNIQUE INDEX IF NOT EXISTS poll_options_id_poll_id_uidx
  ON public.poll_options (id, poll_id);

CREATE TABLE IF NOT EXISTS public.poll_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES public.polls (id) ON DELETE CASCADE,
  option_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (poll_id, user_id)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'poll_votes_option_poll_fk'
  ) THEN
    ALTER TABLE public.poll_votes
      ADD CONSTRAINT poll_votes_option_poll_fk
      FOREIGN KEY (option_id, poll_id)
      REFERENCES public.poll_options (id, poll_id);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS poll_votes_poll_id_idx
  ON public.poll_votes (poll_id);

CREATE INDEX IF NOT EXISTS poll_options_poll_id_idx
  ON public.poll_options (poll_id, sort_order);

INSERT INTO public.polls (id, question, topic_label, active)
VALUES (
  '7a1c0001-0000-4000-8000-000000000001',
  'Which innovation will have the greatest impact on healthcare?',
  'Healthcare innovation',
  true
)
ON CONFLICT (id) DO UPDATE SET
  question = EXCLUDED.question,
  topic_label = EXCLUDED.topic_label,
  active = true;

INSERT INTO public.poll_options (id, poll_id, label, sort_order)
VALUES
  (
    '7a1c0001-0000-4000-8000-000000000011',
    '7a1c0001-0000-4000-8000-000000000001',
    'Artificial Intelligence',
    1
  ),
  (
    '7a1c0001-0000-4000-8000-000000000012',
    '7a1c0001-0000-4000-8000-000000000001',
    'Personalized Nutrition',
    2
  ),
  (
    '7a1c0001-0000-4000-8000-000000000013',
    '7a1c0001-0000-4000-8000-000000000001',
    'Digital Health',
    3
  )
ON CONFLICT (id) DO UPDATE SET
  poll_id = EXCLUDED.poll_id,
  label = EXCLUDED.label,
  sort_order = EXCLUDED.sort_order;

ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.polls, public.poll_options, public.poll_votes
FROM PUBLIC, anon, authenticated;
