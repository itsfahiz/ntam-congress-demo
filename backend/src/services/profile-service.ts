import { getPool } from '../db/pool.js';
import type { AttendeeProfile } from '../types/contracts.js';

type ProfileRow = {
  user_id: string;
  full_name: string;
  organization: string;
  badge_id: string;
  email?: string | null;
};

export function badgeIdFor(userId: string) {
  const compact = String(userId).replace(/-/g, '').toUpperCase();
  const slice = (compact.slice(0, 8) || '00000000').padEnd(8, '0');
  return `NMC-${slice}`;
}

function mapProfile(row: ProfileRow): AttendeeProfile {
  return {
    userId: row.user_id,
    fullName: row.full_name,
    organization: row.organization,
    badgeId: row.badge_id,
    email: row.email ?? null,
  };
}

export async function getProfile(userId: string) {
  const { rows } = await getPool().query<ProfileRow>(
    `SELECT user_id, full_name, organization, badge_id
     FROM public.attendee_profiles
     WHERE user_id = $1
     LIMIT 1`,
    [userId],
  );
  return rows[0] ? mapProfile(rows[0]) : null;
}

export async function upsertProfile({
  userId,
  fullName,
  organization,
}: {
  userId: string;
  fullName: string;
  organization: string;
}) {
  const name = String(fullName ?? '').trim();
  const org = String(organization ?? '').trim();
  const badgeId = badgeIdFor(userId);
  const { rows } = await getPool().query<ProfileRow>(
    `INSERT INTO public.attendee_profiles (user_id, full_name, organization, badge_id)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (user_id)
     DO UPDATE SET
       full_name = EXCLUDED.full_name,
       organization = EXCLUDED.organization,
       updated_at = now()
     RETURNING user_id, full_name, organization, badge_id`,
    [userId, name, org, badgeId],
  );
  return mapProfile(rows[0]!);
}
