import { getPool } from '../db/pool.js';
import type { AttendeeProfile } from '../types/contracts.js';

type ProfileRow = {
  user_id: string;
  full_name: string;
  organization: string;
  phone: string;
  badge_id: string;
  email?: string | null;
};

type ProfileInput = {
  userId: string;
  fullName: string;
  organization: string;
  /** Omitted on legacy registration requests; retain the existing phone. */
  phone?: string;
};

type ProfileStore = {
  get(userId: string): Promise<AttendeeProfile | null>;
  upsert(input: ProfileInput): Promise<AttendeeProfile>;
};

let storeOverride: ProfileStore | null = null;
export function setProfileStoreOverride(store: ProfileStore | null) {
  storeOverride = store;
}

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
    phone: row.phone,
    badgeId: row.badge_id,
    email: row.email ?? null,
  };
}

export async function getPublicBadge(badgeId: string) {
  const { rows } = await getPool().query<{
    full_name: string;
    badge_id: string;
  }>(
    `SELECT full_name, badge_id
     FROM public.attendee_profiles
     WHERE badge_id = $1
     LIMIT 1`,
    [badgeId],
  );
  if (!rows[0]) return null;
  return {
    fullName: rows[0].full_name,
    badgeId: rows[0].badge_id,
  };
}

const postgresStore: ProfileStore = {
  async get(userId) {
    const { rows } = await getPool().query<ProfileRow>(
      `SELECT user_id, full_name, organization, phone, badge_id
       FROM public.attendee_profiles
       WHERE user_id = $1
       LIMIT 1`,
      [userId],
    );
    return rows[0] ? mapProfile(rows[0]) : null;
  },
  async upsert({ userId, fullName, organization, phone }) {
    const badgeId = badgeIdFor(userId);
    const { rows } = await getPool().query<ProfileRow>(
      `INSERT INTO public.attendee_profiles
         (user_id, full_name, organization, phone, badge_id)
       VALUES ($1, $2, $3, COALESCE($4::text, ''), $5)
       ON CONFLICT (user_id)
       DO UPDATE SET
         full_name = EXCLUDED.full_name,
         organization = EXCLUDED.organization,
         phone = COALESCE($4::text, public.attendee_profiles.phone),
         updated_at = now()
       RETURNING user_id, full_name, organization, phone, badge_id`,
      [userId, fullName.trim(), organization.trim(), phone ?? null, badgeId],
    );
    return mapProfile(rows[0]!);
  },
};

function store() {
  return storeOverride ?? postgresStore;
}

export function getProfile(userId: string) {
  return store().get(userId);
}

export function upsertProfile(input: ProfileInput) {
  return store().upsert(input);
}

/** Test fixture. Production routes use the PostgreSQL store. */
export function createMemoryProfileStore(): ProfileStore {
  const profiles = new Map<string, AttendeeProfile>();
  return {
    async get(userId) {
      return profiles.get(userId) ?? null;
    },
    async upsert({ userId, fullName, organization, phone }) {
      const previous = profiles.get(userId);
      const profile: AttendeeProfile = {
        userId,
        fullName: fullName.trim(),
        organization: organization.trim(),
        phone: phone ?? previous?.phone ?? '',
        badgeId: previous?.badgeId ?? badgeIdFor(userId),
        email: null,
      };
      profiles.set(userId, profile);
      return profile;
    },
  };
}
