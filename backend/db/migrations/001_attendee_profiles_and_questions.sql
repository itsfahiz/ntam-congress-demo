-- Repeatable NTAM Congress persistence.
-- Apply in the Supabase SQL editor or: psql "$DATABASE_URL" -f db/migrations/001_attendee_profiles_and_questions.sql

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.attendee_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name text NOT NULL CHECK (char_length(btrim(full_name)) BETWEEN 2 AND 80),
  organization text NOT NULL DEFAULT '',
  badge_id text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 12 AND 240),
  topic text NOT NULL CHECK (topic IN ('general', 'nutrition', 'research', 'clinical')),
  author_name text NOT NULL,
  answered boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS questions_created_at_idx
  ON public.questions (created_at DESC);

CREATE INDEX IF NOT EXISTS questions_user_id_idx
  ON public.questions (user_id);

-- Protect tables from direct client access.
-- All profile and Q&A operations go through our authenticated Express API.

ALTER TABLE public.attendee_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.attendee_profiles, public.questions
FROM PUBLIC, anon, authenticated;