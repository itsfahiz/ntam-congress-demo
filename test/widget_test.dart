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

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
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

  testWidgets('Login screen renders the congress welcome card', (tester) async {
    await pumpPhoneApp(tester);

    expect(find.text('NESTLÉ'), findsOneWidget);
    expect(find.text('CONGRESS'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Sign in with seeded credentials opens Home', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    expect(find.textContaining('Welcome Back'), findsOneWidget);
    expect(find.textContaining('Huda Latheef'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);

    await reveal(tester, find.text('Upcoming Sessions'));
    expect(find.text('Upcoming Sessions'), findsOneWidget);
  });

  testWidgets('Unknown email shows a mock auth error', (tester) async {
    await pumpPhoneApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email'),
      'unknown@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'congress',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(
      find.text('No attendee profile found for that email.'),
      findsOneWidget,
    );
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Register creates a local profile and opens Home', (
    tester,
  ) async {
    await pumpPhoneApp(tester);

    await reveal(tester, find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Join the'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

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
    await reveal(tester, find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await reveal(tester, find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Amira Hassan'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
  });

  testWidgets('Home Agenda shortcut opens the Agenda screen', (tester) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Congress Agenda'), findsWidgets);
    expect(find.text("Today's Sessions"), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsOneWidget);
  });
}
