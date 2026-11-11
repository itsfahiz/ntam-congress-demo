import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import 'data/assistant_models.dart';

CongressSession? catalogSession(String id) {
  for (final session in CongressCatalog.sessions) {
    if (session.id == id) return session;
  }
  return null;
}

CongressSpeaker? catalogSpeaker(String id) {
  for (final speaker in CongressCatalog.speakers) {
    if (speaker.id == id) return speaker;
  }
  return null;
}

String sourceLabel(AssistantSource source) {
  if (source.isSession) {
    return catalogSession(source.id)?.title ?? 'Session';
  }
  if (source.isSpeaker) {
    return catalogSpeaker(source.id)?.fullName ?? 'Speaker';
  }
  if (source.isDay) {
    if (source.id == 'day1') return 'Day 1';
    if (source.id == 'day2') return 'Day 2';
    return 'Schedule';
  }
  return source.type;
}

bool canOpenSource(AssistantSource source) {
  if (source.isSession) return catalogSession(source.id) != null;
  if (source.isSpeaker) return catalogSpeaker(source.id) != null;
  if (source.isDay) return source.id == 'day1' || source.id == 'day2';
  return false;
}
