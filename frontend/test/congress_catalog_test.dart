import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/app_routes.dart';
import 'package:ntam_congress_demo/features/auth/auth_validators.dart';
import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/congress/data/congress_catalog.dart';
import 'package:ntam_congress_demo/features/name_tag/data/mock_badge_qr_repository.dart';

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

  test('mock verification URL encodes only the badge id', () {
    final attendee = MockAuthRepository.demoAttendee;
    final url = MockBadgeQrRepository.urlFor(attendee.id);
    expect(
      url,
      startsWith('https://ntam-congress-api.onrender.com/badge/verify?'),
    );
    expect(url, contains('b=NMC-2026-001'));
    expect(url.contains(attendee.email), isFalse);
    expect(url.contains(attendee.phone), isFalse);
  });

  test('scientific programme summary uses catalog sessions', () {
    final summary = CongressCatalog.scientificProgrammeSummary();
    expect(summary, contains('Opening Ceremony'));
    expect(summary, contains('Dr. Sarah Johnson'));
    expect(summary, contains('Main Auditorium'));
  });

  test('resource search finds pediatric guide only', () {
    final matches = CongressCatalog.filterResources(query: 'Pediatric');
    expect(matches, hasLength(1));
    expect(matches.first.id, 'pediatric-guide');
  });

  test('venue map pin uses the official DWTC coordinates', () {
    final venue = CongressCatalog.venue;
    expect(venue.latitude, 25.2230544);
    expect(venue.longitude, 55.2885219);
    expect(venue.mapMarkerLabel, 'Dubai World Trade Centre');
    expect(
      venue.directionsUrl,
      'https://www.google.com/maps/search/?api=1&query=25.2230544%2C55.2885219',
    );
    expect(venue.address, 'World Trade Centre, Dubai, United Arab Emirates');
    expect(venue.addressDisclaimer, contains('not a confirmed congress booking'));
  });

  test('every Quick Access shortcut uses a known app route', () {
    const known = {
      AppRoutes.agenda,
      AppRoutes.speakers,
      AppRoutes.nameTag,
      AppRoutes.venue,
      AppRoutes.voting,
      AppRoutes.qa,
      AppRoutes.resources,
      AppRoutes.exhibitors,
    };
    final routes = CongressCatalog.quickAccessItems.map((item) => item.route);
    expect(routes.toSet(), known);
  });

  test('auth validators reject empty and invalid input', () {
    expect(AuthValidators.email(''), 'Please enter your email.');
    expect(
      AuthValidators.email('not-an-email'),
      'Enter a valid email address.',
    );
    expect(AuthValidators.email('huda@example.com'), isNull);
    expect(AuthValidators.password(''), 'Please enter your password.');
    expect(
      AuthValidators.password('123'),
      'Password must be at least 6 characters.',
    );
    expect(AuthValidators.fullName('A'), 'Enter at least two characters.');
    expect(AuthValidators.organization(''), isNotNull);
  });
}
