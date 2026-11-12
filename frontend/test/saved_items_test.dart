import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/saved/data/mock_saved_items_repository.dart';
import 'package:ntam_congress_demo/features/profile/profile_screen.dart';
import 'package:ntam_congress_demo/features/saved/state/saved_items_controller.dart';

import 'support/home_shortcuts.dart';

void main() {
  test('saved session and resource survive reloading and are isolated by attendee', () async {
    final controller = SavedItemsController(MockSavedItemsRepository());
    addTearDown(controller.dispose);

    await controller.loadFor('huda@example.com');
    expect(controller.count, 0);
    await controller.toggle('session', 'opening');
    await controller.toggle('resource', 'programme');
    expect(controller.count, 2);
    expect(controller.countFor('session'), 1);
    expect(controller.countFor('resource'), 1);

    await controller.loadFor('amira@example.com');
    expect(controller.count, 0);
    await controller.loadFor('huda@example.com');
    expect(controller.count, 2);
    await controller.toggle('session', 'opening');
    expect(controller.isSaved('session', 'opening'), false);
    expect(controller.isSaved('resource', 'programme'), true);
  });

  testWidgets('bookmarking Agenda updates Profile Saved and opens saved sessions', (tester) async {
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

    await tapHomeShortcut(tester, 'Agenda');
    await tester.tap(find.byTooltip('Bookmark session').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);
    // The stat row is below the contact card on a phone-sized screen.
    // Sliver children outside the viewport are not built until scrolled in.
    await tester.scrollUntilVisible(
      find.text('Saved'),
      150,
      scrollable: find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('01'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved Items'), findsOneWidget);
    expect(find.text('Opening Ceremony'), findsOneWidget);

    await tester.tap(find.text('Resources (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No saved resources yet.'), findsOneWidget);
  });
}
