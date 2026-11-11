import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/auth/data/auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/domain/attendee.dart';
import 'package:ntam_congress_demo/features/auth/state/auth_controller.dart';

void main() {
  Future<void> pumpPhoneApp(
    WidgetTester tester, {
    AuthController? authController,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CongressApp(authController: authController),
    );
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

  Future<void> openRegister(WidgetTester tester) async {
    await reveal(tester, find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
  }

  Future<void> fillRegisterForm(
    WidgetTester tester, {
    required String name,
    required String email,
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      name,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      email,
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
  }

  testWidgets(
    'pending email confirmation shows Account Created and hides the form',
    (tester) async {
      await pumpPhoneApp(
        tester,
        authController: AuthController(_PendingConfirmAuthRepository()),
      );
      await openRegister(tester);
      await fillRegisterForm(
        tester,
        name: 'Amira Hassan',
        email: 'amira@example.com',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Account Created!'), findsOneWidget);
      expect(
        find.text("You're one step away from joining the Nestlé Congress."),
        findsOneWidget,
      );
      expect(
        find.text(
          "We've sent a confirmation link to your email. Verify your email before signing in.",
        ),
        findsOneWidget,
      );
      expect(find.text('amira@example.com'), findsOneWidget);
      expect(find.text('Continue to Sign In'), findsOneWidget);
      expect(find.text('Create password'), findsNothing);
      expect(find.text('Create Account'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(
        find.text('Account created. Check your email to confirm before signing in.'),
        findsNothing,
      );
      expect(find.text('Email verified successfully'), findsNothing);
    },
  );

  testWidgets(
    'Continue to Sign In opens login with email prefilled and empty password',
    (tester) async {
      await pumpPhoneApp(
        tester,
        authController: AuthController(_PendingConfirmAuthRepository()),
      );
      await openRegister(tester);
      await fillRegisterForm(
        tester,
        name: 'Amira Hassan',
        email: 'amira@example.com',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Continue to Sign In'), findsNothing);

      final emailField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Enter your email'),
      );
      expect(emailField.controller?.text, 'amira@example.com');

      final passwordField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Enter your password'),
      );
      expect(passwordField.controller?.text, isEmpty);
    },
  );

  testWidgets('failed registration keeps the form and shows the error', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await openRegister(tester);
    await fillRegisterForm(
      tester,
      name: 'Huda Latheef',
      email: 'huda@example.com',
    );
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(
      find.text('An attendee profile already exists for that email.'),
      findsOneWidget,
    );
    expect(find.text('Account Created!'), findsNothing);
    expect(find.text('Create password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  test('AuthController does not sign in when confirmation is required', () async {
    final controller = AuthController(_PendingConfirmAuthRepository());
    await controller.restoreSession();

    await expectLater(
      controller.register(
        const RegistrationDraft(
          fullName: 'Amira Hassan',
          email: 'amira@example.com',
          organization: 'Dubai Hospital',
          password: 'congress',
        ),
      ),
      throwsA(isA<EmailConfirmationRequiredException>()),
    );
    expect(controller.isSignedIn, isFalse);
    expect(controller.attendee, isNull);
    expect(controller.error, isNull);
  });
}

class _PendingConfirmAuthRepository implements AuthRepository {
  @override
  String? get accessToken => null;

  @override
  Future<Attendee?> restoreSession() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<Attendee> signIn({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      'Check your email to confirm the account before signing in.',
    );
  }

  @override
  Future<Attendee> register(RegistrationDraft draft) async {
    throw EmailConfirmationRequiredException(
      email: draft.email.trim().toLowerCase(),
    );
  }
}
