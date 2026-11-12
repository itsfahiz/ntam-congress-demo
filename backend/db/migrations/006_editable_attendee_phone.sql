-- 006: Editable attendee phone field.
-- Apply AFTER 005_saved_items.sql, BEFORE deploying the profile API.
-- Additive migration: existing profiles, badges, questions and saved items stay intact.
ALTER TABLE public.attendee_profiles
  ADD COLUMN IF NOT EXISTS phone text NOT NULL DEFAULT '';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'attendee_profiles_phone_valid'
      AND conrelid = 'public.attendee_profiles'::regclass
  ) THEN
    ALTER TABLE public.attendee_profiles
      ADD CONSTRAINT attendee_profiles_phone_valid
      CHECK (
        phone = ''
        OR (
          phone ~ '^[+0-9() -]+$'
          AND length(regexp_replace(phone, '[^0-9]', '', 'g')) BETWEEN 7 AND 15
          AND char_length(phone) <= 32
        )
      );
  END IF;
END $$;

-- Existing RLS and table grants remain unchanged.
