import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ntam_congress_demo/app/app_routes.dart';
import 'package:ntam_congress_demo/app/congress_app.dart';

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

  Future<void> openFromQuickAccess(
    WidgetTester tester,
    String description,
  ) async {
    await tester.tap(find.text('View All').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(description),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(description));
    await tester.pumpAndSettle();
  }

  Future<void> registerAmira(WidgetTester tester) async {
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
  }

  testWidgets('Resources search filters the actual demo media catalogue', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await openFromQuickAccess(tester, 'Slides, PDFs and session files');

    expect(find.text('Congress Library'), findsOneWidget);
    expect(find.text('Congress Scientific Programme'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Pediatric');
    await tester.pumpAndSettle();

    expect(find.text('Pediatric Nutrition Guide'), findsOneWidget);
    expect(find.text('Congress Scientific Programme'), findsNothing);
    expect(find.text('Keynote Presentation Slides'), findsNothing);

    expect(find.text('Pediatric Nutrition Guide'), findsOneWidget);
    expect(find.byTooltip('Download'), findsOneWidget);
  });

  testWidgets('Resources folder icon browses existing catalog groups', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await openFromQuickAccess(tester, 'Slides, PDFs and session files');

    expect(find.text('Congress Scientific Programme'), findsOneWidget);
    expect(find.text('Keynote Presentation Slides'), findsOneWidget);

    await tester.tap(find.byTooltip('Browse folders'));
    await tester.pumpAndSettle();

    expect(find.text('PDFs'), findsOneWidget);
    expect(find.text('Slides'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Congress Scientific Programme'), findsNothing);

    await tester.tap(find.text('PDFs'));
    await tester.pumpAndSettle();

    expect(find.text('Congress Scientific Programme'), findsOneWidget);
    expect(find.text('Pediatric Nutrition Guide'), findsOneWidget);
    expect(find.text('Keynote Presentation Slides'), findsNothing);
    expect(find.text('Introduction to Food & Health'), findsNothing);

    await tester.tap(find.byTooltip('Browse folders'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show list'));
    await tester.pumpAndSettle();

    expect(find.text('Congress Scientific Programme'), findsOneWidget);
    expect(find.text('Keynote Presentation Slides'), findsOneWidget);
    expect(find.text('PDFs'), findsNothing);
  });

  testWidgets('Exhibitors opens illustrative demo booths', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await openFromQuickAccess(tester, 'Discover partner booths');

    expect(find.text('Demo booths'), findsOneWidget);
    expect(find.text('Illustrative booths'), findsOneWidget);
    expect(find.text('ILLUSTRATIVE'), findsWidgets);
    expect(find.text('Nutrition Science Pavilion'), findsOneWidget);

    await tester.tap(find.text('Nutrition Science Pavilion'));
    await tester.pumpAndSettle();
    expect(find.text('ILLUSTRATIVE'), findsWidgets);
    expect(
      find.textContaining('tied to the pediatric nutrition sessions'),
      findsOneWidget,
    );
  });

  testWidgets('Profile shows seeded attendee details', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Huda Latheef'), findsOneWidget);
    expect(find.text('huda@example.com'), findsOneWidget);
    expect(find.text('ID: NMC-2026-001'), findsOneWidget);
    expect(find.text('+971 56 283 4212'), findsOneWidget);
    expect(find.text('Dubai, UAE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sign Out'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sign Out'), findsOneWidget);
    expect(find.text('NTAM'), findsOneWidget);
    expect(find.text('08'), findsOneWidget);
  });

  testWidgets('Profile shows a newly registered attendee', (tester) async {
    await pumpPhoneApp(tester);
    await registerAmira(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Amira Hassan'), findsOneWidget);
    expect(find.text('amira@example.com'), findsOneWidget);
    expect(find.text('ID: NMC-2026-002'), findsOneWidget);
    expect(find.text('Huda Latheef'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Dubai Hospital'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Dubai Hospital'), findsOneWidget);
  });

  testWidgets('Sign Out returns to Login and blocks protected routes', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sign Out'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Huda Latheef'), findsNothing);

    final context = tester.element(find.text('Sign In'));
    GoRouter.of(context).go(AppRoutes.agenda);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Congress Agenda'), findsNothing);
  });
}
