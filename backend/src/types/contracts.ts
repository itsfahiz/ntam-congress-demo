export type CatalogDayId = 'day1' | 'day2';
export type SessionTrack = 'keynote' | 'nutrition' | 'research';
export type SpeakerFocus = 'nutrition' | 'pediatrics' | 'research';
export type QuestionTopic = 'general' | 'nutrition' | 'research' | 'clinical';
export type SourceType = 'session' | 'speaker' | 'day';

export type CatalogVenue = {
  name: string;
  dateLabel: string;
  address: string;
  facilities: string[];
};

export type CatalogDay = {
  id: CatalogDayId;
  shortLabel: string;
  dateShort: string;
  headline: string;
  dateLong: string;
};

export type CatalogEvent = {
  title: string;
  dateLabel: string;
  location: string;
  venue: CatalogVenue;
  days: CatalogDay[];
};

export type CatalogSpeaker = {
  id: string;
  fullName: string;
  title: string;
  country: string;
  focuses: SpeakerFocus[];
  featured: boolean;
  listed: boolean;
  bio: string;
};

export type CatalogSession = {
  id: string;
  day: CatalogDayId;
  title: string;
  speakerId: string;
  location: string;
  timeLabel: string;
  hour: number;
  minute: number;
  track: SessionTrack;
  highlighted: boolean;
  summary: string;
};

export type SessionWithSpeaker = CatalogSession & {
  speakerName: string | null;
};

export type SpeakerWithInitials = CatalogSpeaker & {
  initials: string;
};

export type AssistantSource = {
  type: SourceType;
  id: string;
};

export type AssistantReply = {
  answer: string;
  grounded: boolean;
  sources: AssistantSource[];
};

export type SessionPayload = CatalogSession & {
  type: 'session';
  speakerName: string | null;
  dayLabel: string;
};

export type SpeakerPayload = CatalogSpeaker & {
  type: 'speaker';
};

export type DayPayload = CatalogDay & {
  type: 'day';
  eventTitle: string;
  eventDateLabel: string;
  eventLocation: string;
  venue: CatalogVenue;
};

export type RetrievalRecord =
  | { type: 'session'; id: string; payload: SessionPayload }
  | { type: 'speaker'; id: string; payload: SpeakerPayload }
  | { type: 'day'; id: string; payload: DayPayload };

export type AuthUser = {
  id: string;
  email?: string | null;
  user_metadata?: Record<string, unknown>;
};

export type AttendeeProfile = {
  userId: string;
  fullName: string;
  organization: string;
  badgeId: string;
  email: string | null;
};

export type QuestionRecord = {
  id: string;
  userId: string;
  body: string;
  topic: QuestionTopic;
  authorName: string;
  answered: boolean;
  createdAt: Date | string;
  likeCount: number;
  replyCount: number;
  likedByMe: boolean;
};

export type QuestionReplyRecord = {
  id: string;
  questionId: string;
  body: string;
  authorName: string;
  createdAt: Date | string;
};

export type GeminiGenerateArgs = {
  question: string;
  records: RetrievalRecord[];
};

export type GenerateContentFn = (
  args: GeminiGenerateArgs,
) => Promise<string>;
