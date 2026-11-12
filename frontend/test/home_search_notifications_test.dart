import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';

void main() {
  Future<void> signIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const CongressApp());
    await tester.pumpAndSettle();
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

  testWidgets('Home search opens searchable sessions, speakers and resources',
      (tester) async {
    await signIn(tester);
    await tester.tap(find.text('Search sessions, speakers, topics...'));
    await tester.pumpAndSettle();
    expect(find.text('Search Congress'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Search sessions, speakers, topics...'),
      'pediatric',
    );
    await tester.pumpAndSettle();
    expect(find.text('Future of Pediatric Nutrition'), findsOneWidget);
    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
    expect(find.text('Pediatric Nutrition Guide'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsNothing);
    await tester.tap(find.text('Speakers'));
    await tester.pumpAndSettle();
    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
    expect(find.text('Pediatric Nutrition Guide'), findsNothing);
  });

  testWidgets('Search session opens matching detail on the Agenda page',
      (tester) async {
    await signIn(tester);
    await tester.tap(find.text('Search sessions, speakers, topics...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opening Ceremony'));
    await tester.pumpAndSettle();
    expect(find.text('Congress Agenda'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsWidgets);
    expect(find.text('Main Auditorium'), findsWidgets);
  });

  testWidgets('Search speaker opens detail on the Speakers page',
      (tester) async {
    await signIn(tester);
    await tester.tap(find.text('Search sessions, speakers, topics...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speakers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr. Sarah Johnson'));
    await tester.pumpAndSettle();
    expect(find.text('Global Medical'), findsWidgets);
    expect(find.text('Pediatric Nutrition Specialist'), findsWidgets);
  });

  testWidgets('Home filter opens full event search and day/track filters',
      (tester) async {
    await signIn(tester);
    await tester.tap(find.byTooltip('Filter sessions'));
    await tester.pumpAndSettle();
    expect(find.text('Search Congress'), findsOneWidget);
    expect(find.text('Search filters'), findsOneWidget);
    await tester.tap(find.text('Day 2'));
    await tester.tap(find.text('Nutrition'));
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();
    expect(find.text('Nutrition Policy Roundtable'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsNothing);
  });

  testWidgets('Notification bell opens dedicated page and links to features',
      (tester) async {
    await signIn(tester);
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Programme notices'), findsOneWidget);
    expect(find.textContaining('not live push alerts'), findsOneWidget);
    await tester.tap(find.text('Congress Q&A'));
    await tester.pumpAndSettle();
    expect(find.text('Ask Q&A'), findsWidgets);
  });
}
