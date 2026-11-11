import { createHmac, timingSafeEqual } from 'node:crypto';
import type { AttendeeProfile } from '../types/contracts.js';
import { getProfile, getPublicBadge } from './profile-service.js';
import { publicError } from '../types/http.js';

const MESSAGE_PREFIX = 'nmc-badge:v1:';

export type PublicBadge = {
  fullName: string;
  badgeId: string;
};

type PublicBadgeLookup = (badgeId: string) => Promise<PublicBadge | null>;
type ProfileLookup = (userId: string) => Promise<AttendeeProfile | null>;

let lookupOverride: PublicBadgeLookup | null = null;
let profileOverride: ProfileLookup | null = null;

export function setPublicBadgeLookupOverride(fn: PublicBadgeLookup | null) {
  lookupOverride = fn;
}

export function setProfileLookupOverride(fn: ProfileLookup | null) {
  profileOverride = fn;
}

function configuredSigningSecret() {
  return process.env.BADGE_SIGNING_SECRET?.trim() || '';
}

export function badgeSigningSecret() {
  const secret = configuredSigningSecret();
  if (!secret) {
    throw publicError(503, 'Badge signing is not configured.', 'not_configured');
  }
  return secret;
}

export function signBadgeId(badgeId: string, secret = badgeSigningSecret()) {
  return createHmac('sha256', secret)
    .update(`${MESSAGE_PREFIX}${badgeId}`)
    .digest('hex');
}

export function isValidBadgeSignature(
  badgeId: string,
  signature: string,
  secret = configuredSigningSecret(),
) {
  if (!secret || !/^[a-f0-9]{64}$/i.test(signature)) return false;
  const expected = signBadgeId(badgeId, secret);
  const left = Buffer.from(expected, 'hex');
  const right = Buffer.from(signature, 'hex');
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

export function buildVerifyUrl(origin: string, badgeId: string, signature: string) {
  const base = origin.replace(/\/$/, '');
  const url = new URL('/badge/verify', `${base}/`);
  url.searchParams.set('b', badgeId);
  url.searchParams.set('s', signature);
  return url.toString();
}

export async function issueBadge(userId: string, origin: string) {
  const profile = profileOverride
    ? await profileOverride(userId)
    : await getProfile(userId);
  if (!profile) {
    throw publicError(404, 'Attendee profile not found.');
  }
  const signature = signBadgeId(profile.badgeId);
  return {
    badgeId: profile.badgeId,
    verifyUrl: buildVerifyUrl(origin, profile.badgeId, signature),
  };
}

export async function lookupPublicBadge(badgeId: string) {
  if (lookupOverride) return lookupOverride(badgeId);
  return getPublicBadge(badgeId);
}
