-- Idempotent seed of congress polls 2 and 3.
-- Does not modify poll 1 (7a1c0001-0000-4000-8000-000000000001) or its votes.
-- Apply in the Supabase SQL editor or: psql "$DATABASE_URL" -f db/migrations/003_add_congress_polls.sql

INSERT INTO public.polls (id, question, topic_label, active)
VALUES (
  '7a1c0001-0000-4000-8000-000000000002',
  'Which topic would you most like to explore at a future medical congress?',
  'Future congress',
  true
)
ON CONFLICT (id) DO UPDATE SET
  question = EXCLUDED.question,
  topic_label = EXCLUDED.topic_label,
  active = true;

INSERT INTO public.polls (id, question, topic_label, active)
VALUES (
  '7a1c0001-0000-4000-8000-000000000003',
  'Which session format helps you learn most effectively?',
  'Learning format',
  true
)
ON CONFLICT (id) DO UPDATE SET
  question = EXCLUDED.question,
  topic_label = EXCLUDED.topic_label,
  active = true;

INSERT INTO public.poll_options (id, poll_id, label, sort_order)
VALUES
  (
    '7a1c0001-0000-4000-8000-000000000021',
    '7a1c0001-0000-4000-8000-000000000002',
    'Pediatric Nutrition',
    1
  ),
  (
    '7a1c0001-0000-4000-8000-000000000022',
    '7a1c0001-0000-4000-8000-000000000002',
    'Clinical Research',
    2
  ),
  (
    '7a1c0001-0000-4000-8000-000000000023',
    '7a1c0001-0000-4000-8000-000000000002',
    'Preventive Healthcare',
    3
  ),
  (
    '7a1c0001-0000-4000-8000-000000000031',
    '7a1c0001-0000-4000-8000-000000000003',
    'Expert Panel Discussions',
    1
  ),
  (
    '7a1c0001-0000-4000-8000-000000000032',
    '7a1c0001-0000-4000-8000-000000000003',
    'Clinical Case Studies',
    2
  ),
  (
    '7a1c0001-0000-4000-8000-000000000033',
    '7a1c0001-0000-4000-8000-000000000003',
    'Interactive Workshops',
    3
  )
ON CONFLICT (id) DO UPDATE SET
  poll_id = EXCLUDED.poll_id,
  label = EXCLUDED.label,
  sort_order = EXCLUDED.sort_order;
