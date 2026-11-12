import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/state/auth_controller.dart';

void main() {
  test('edited profile stays stored after sign-out and sign-in', () async {
    final repository = MockAuthRepository();
    final auth = AuthController(repository);
    addTearDown(auth.dispose);
    await auth.restoreSession();

    await auth.signIn(email: 'huda@example.com', password: 'congress');
    final badge = auth.attendee!.id;
    await auth.updateProfile(
      fullName: 'Huda Updated',
      organization: 'Dubai Clinic',
      phone: '+971 50 123 4567',
    );
    expect(auth.attendee!.fullName, 'Huda Updated');
    expect(auth.attendee!.phone, '+971 50 123 4567');
    expect(auth.attendee!.id, badge);

    await auth.signOut();
    await auth.signIn(email: 'huda@example.com', password: 'congress');
    expect(auth.attendee!.fullName, 'Huda Updated');
    expect(auth.attendee!.organization, 'Dubai Clinic');
    expect(auth.attendee!.phone, '+971 50 123 4567');
  });

  testWidgets('profile edit sheet saves and refreshes visible details', (tester) async {
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

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Huda Updated',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hospital / Organization'),
      'Dubai Clinic',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone number (optional)'),
      '+971 50 123 4567',
    );
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Huda Updated'), findsOneWidget);
    expect(find.text('+971 50 123 4567'), findsOneWidget);
    expect(find.text('ID: NMC-2026-001'), findsOneWidget);
  });
}
