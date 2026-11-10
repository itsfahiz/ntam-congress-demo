import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> openQuickAccess(WidgetTester tester) async {
    await tester.tap(find.text('View All').first);
    await tester.pumpAndSettle();
  }

  testWidgets('Quick Access View All opens tools and navigates to Speakers', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await openQuickAccess(tester);

    expect(find.text('Explore Congress Tools'), findsOneWidget);
    expect(find.text('View full congress schedule'), findsOneWidget);

    await tester.tap(find.text('Speakers'));
    await tester.pumpAndSettle();

    expect(find.text('Speakers'), findsWidgets);
    expect(find.text('Global Medical Experts'), findsOneWidget);
    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Congress Tools'), findsOneWidget);
  });

  testWidgets('Quick Access Agenda card opens Congress Agenda', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await openQuickAccess(tester);

    await tester.tap(find.text('View full congress schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Congress Agenda'), findsOneWidget);
    expect(find.text('Day 1 Schedule'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsOneWidget);
  });

  testWidgets('Agenda day selection shows Day 2 sessions only', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Opening Ceremony'), findsOneWidget);
    expect(find.text('Nutrition Policy Roundtable'), findsNothing);

    await tester.tap(find.text('Day 2'));
    await tester.pumpAndSettle();

    expect(find.text('Day 2 Schedule'), findsOneWidget);
    expect(find.text('Nutrition Policy Roundtable'), findsOneWidget);
    expect(find.text('Closing Keynote'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsNothing);
  });

  testWidgets('Agenda track chip filters Day 1 to Nutrition', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();

    expect(find.text('Future of Pediatric Nutrition'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsNothing);
    expect(find.text('Clinical Research Highlights'), findsNothing);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Opening Ceremony'), findsOneWidget);
    expect(find.text('Future of Pediatric Nutrition'), findsOneWidget);
  });
}
