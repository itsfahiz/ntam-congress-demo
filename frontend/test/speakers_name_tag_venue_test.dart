import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/name_tag/data/badge_qr_repository.dart';
import 'package:ntam_congress_demo/features/name_tag/data/mock_badge_qr_repository.dart';

import 'support/home_shortcuts.dart';

class _FailingBadgeQrRepository implements BadgeQrRepository {
  @override
  Future<String> issueVerifyUrl() async {
    throw const BadgeQrException('Could not load your verification badge.');
  }
}

void main() {
  Future<void> pumpPhoneApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const CongressApp());
    await tester.pumpAndSettle();
  }

  Future<void> signInAsDemo(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email'),
      'huda@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'congress',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  testWidgets('Speaker search and Pediatrics filter hide unmatched faculty', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tapHomeShortcut(tester, 'Speakers');

    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
    expect(find.text('Dr. Hassan Ali'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sarah');
    await tester.pumpAndSettle();

    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
    expect(find.text('Dr. Hassan Ali'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pediatrics').last);
    await tester.pumpAndSettle();

    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
    expect(find.text('Dr. Ahmed Khalid'), findsNothing);
  });

  testWidgets('Speaker detail lists catalog sessions', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Speakers');

    await tester.tap(find.text('Dr. Sarah Johnson'));
    await tester.pumpAndSettle();

    expect(find.text('Future of Pediatric Nutrition'), findsWidgets);
    expect(find.text('Nutrition Policy Roundtable'), findsOneWidget);
    expect(
      find.textContaining('Demo faculty profile for the assessment app'),
      findsOneWidget,
    );
  });

  testWidgets('Name Tag shows signed-in attendee and verification QR', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Name Tag');

    expect(find.text('Huda Latheef'), findsOneWidget);
    expect(find.text('NTAM · Medical Congress Attendee'), findsOneWidget);
    expect(find.text('Dubai, UAE'), findsOneWidget);
    expect(find.text('22 - 23 May 2026'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(QrImageView),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('NMC-2026-001'), findsOneWidget);
    expect(find.text('Scan to verify attendee'), findsOneWidget);
    expect(find.text('Demo badge'), findsNothing);

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    final payload = (qr.key as ValueKey<String>).value;
    expect(payload, MockBadgeQrRepository.urlFor('NMC-2026-001'));
    expect(payload, startsWith('https://'));
    expect(payload, contains('/badge/verify?b=NMC-2026-001'));
    expect(payload.contains('huda@example.com'), isFalse);
  });

  testWidgets('Registered attendee name and badge id appear on Name Tag', (
    tester,
  ) async {
    await pumpPhoneApp(tester);

    await tester.scrollUntilVisible(
      find.text('Create Account'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Amira Hassan',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'amira@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hospital / Organization'),
      'Dubai Hospital',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Create password'),
      'congress',
    );
    await tester.scrollUntilVisible(
      find.byType(Checkbox),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Checkbox));
    await tester.scrollUntilVisible(
      find.text('Create Account'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    await tapHomeShortcut(tester, 'Name Tag');

    expect(find.text('Amira Hassan'), findsOneWidget);
    expect(
      find.text('Dubai Hospital · Medical Congress Attendee'),
      findsOneWidget,
    );
    expect(find.text('Dubai, UAE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(QrImageView),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('NMC-2026-002'), findsOneWidget);
    expect(find.text('Scan to verify attendee'), findsOneWidget);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(
      (qr.key as ValueKey<String>).value,
      MockBadgeQrRepository.urlFor('NMC-2026-002'),
    );
  });

  testWidgets('Name Tag shows an error and no QR when issuance fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CongressApp(badgeQrRepository: _FailingBadgeQrRepository()),
    );
    await tester.pumpAndSettle();
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Name Tag');

    expect(find.text('Huda Latheef'), findsOneWidget);
    expect(find.text('NMC-2026-001'), findsOneWidget);
    expect(find.text('Could not load your verification badge.'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Demo badge'), findsNothing);
  });

  testWidgets('Venue shows reference copy and demo disclaimer', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Venue');

    expect(
      find.text('Dubai International Convention & Exhibition Center'),
      findsOneWidget,
    );
    expect(
      find.text('World Trade Centre, Dubai, United Arab Emirates'),
      findsOneWidget,
    );
    expect(find.text('Free Wi-Fi'), findsOneWidget);
    await tester.tap(find.byTooltip('Directions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not a verified pin'), findsOneWidget);
  });
}
