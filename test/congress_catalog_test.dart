import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/congress/data/congress_catalog.dart';
import 'package:ntam_congress_demo/features/name_tag/demo_badge_qr.dart';

void main() {
  test('listed speakers own the sessions shown on their cards', () {
    for (final speaker in CongressCatalog.listedSpeakers) {
      final sessions = CongressCatalog.sessionsForSpeaker(speaker.id);
      expect(sessions, isNotEmpty, reason: speaker.fullName);
      for (final session in sessions) {
        expect(session.speakerId, speaker.id);
        expect(CongressCatalog.speakerName(session), speaker.fullName);
      }
    }
  });

  test('session speaker ids resolve without duplicate names in catalog', () {
    for (final session in CongressCatalog.sessions) {
      expect(
        CongressCatalog.speakerById(session.speakerId).fullName,
        isNotEmpty,
      );
    }
  });

  test('speaker initials skip Dr titles', () {
    expect(CongressCatalog.speakerById(CongressCatalog.sarahId).initials, 'SJ');
    expect(
      CongressCatalog.speakerById(CongressCatalog.hassanId).initials,
      'HA',
    );
  });

  test('demo badge QR encodes only the badge id', () {
    final attendee = MockAuthRepository.demoAttendee;
    expect(DemoBadgeQr.payloadFor(attendee), 'NMC-DEMO-BADGE:NMC-2026-001');
    expect(DemoBadgeQr.payloadFor(attendee).contains(attendee.email), isFalse);
    expect(DemoBadgeQr.payloadFor(attendee).contains(attendee.phone), isFalse);
  });
}
