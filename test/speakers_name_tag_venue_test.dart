import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/name_tag/demo_badge_qr.dart';

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

    await tester.tap(find.text('Speakers'));
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Speakers'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dr. Sarah Johnson'));
    await tester.pumpAndSettle();

    expect(find.text('Future of Pediatric Nutrition'), findsWidgets);
    expect(find.text('Nutrition Policy Roundtable'), findsOneWidget);
    expect(
      find.textContaining('Demo faculty profile for the assessment app'),
      findsOneWidget,
    );
  });

  testWidgets('Name Tag shows demo attendee and demo QR payload', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await tester.tap(find.text('Name Tag'));
    await tester.pumpAndSettle();

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
    expect(
      find.text('Demo badge QR. Not connected to check-in or verification.'),
      findsOneWidget,
    );

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect((qr.key as ValueKey<String>).value, 'NMC-DEMO-BADGE:NMC-2026-001');
    expect(
      DemoBadgeQr.isDemoPayload((qr.key as ValueKey<String>).value),
      isTrue,
    );
  });

  testWidgets('Registered attendee name and badge id appear on Name Tag', (
    tester,
  ) async {
    await pumpPhoneApp(tester);

    await tester.scrollUntilVisible(
      find.text('Create Account →'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Create Account →'));
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

    await tester.tap(find.text('Name Tag'));
    await tester.pumpAndSettle();

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
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect((qr.key as ValueKey<String>).value, 'NMC-DEMO-BADGE:NMC-2026-002');
  });

  testWidgets('Venue shows reference copy and demo disclaimer', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await tester.tap(find.text('Venue'));
    await tester.pumpAndSettle();

    expect(
      find.text('Dubai International Convention & Exhibition Center'),
      findsOneWidget,
    );
    expect(
      find.text('World Trade Centre, Dubai, United Arab Emirates'),
      findsOneWidget,
    );
    expect(find.textContaining('not a verified pin'), findsOneWidget);
    expect(find.text('Free Wi-Fi'), findsOneWidget);
  });
}
