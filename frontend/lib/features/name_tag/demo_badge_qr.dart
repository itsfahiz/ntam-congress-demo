import '../auth/domain/attendee.dart';

/// Local demo badge payload. Encodes only the attendee badge id.
abstract final class DemoBadgeQr {
  static const prefix = 'NMC-DEMO-BADGE:';

  static String payloadFor(Attendee attendee) => '$prefix${attendee.id}';

  static bool isDemoPayload(String value) => value.startsWith(prefix);
}
