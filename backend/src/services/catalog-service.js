import { event, sessions, speakers } from '../../data/catalog.js';

const TITLE_SKIP = /^dr\.?$/i;

export function speakerInitials(fullName) {
  const parts = fullName
    .trim()
    .split(/\s+/)
    .filter((part) => part.length > 0 && !TITLE_SKIP.test(part));
  if (parts.length === 0) return 'NA';
  return parts
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');
}

function withSpeaker(session) {
  const speaker = speakers.find((item) => item.id === session.speakerId);
  return {
    ...session,
    speakerName: speaker?.fullName ?? null,
  };
}

function withInitials(speaker) {
  return {
    ...speaker,
    initials: speakerInitials(speaker.fullName),
  };
}

export function getEvent() {
  return event;
}

export function getSessions({ day, track } = {}) {
  return sessions
    .filter((session) => (day ? session.day === day : true))
    .filter((session) => (track ? session.track === track : true))
    .map(withSpeaker);
}

export function getSpeakers({ listed } = {}) {
  return speakers
    .filter((speaker) => (listed === undefined ? true : speaker.listed === listed))
    .map(withInitials);
}
