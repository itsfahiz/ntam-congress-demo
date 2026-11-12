import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/auth/data/auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/domain/attendee.dart';
import 'package:ntam_congress_demo/features/auth/state/auth_controller.dart';

void main() {
  Future<void> pumpPhone(WidgetTester tester, AuthController controller) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CongressApp(authController: controller));
  }

  testWidgets('startup with a restored session goes to Home, not Login', (
    tester,
  ) async {
    final repository = _DeferredAuthRepository();
    final controller = AuthController(repository);
    await pumpPhone(tester, controller);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(find.text('Quick Access'), findsNothing);

    repository.complete(MockAuthRepository.demoAttendee);
    await tester.pumpAndSettle();

    expect(find.textContaining('Huda Latheef'), findsOneWidget);
    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(find.text('Welcome Back'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('startup without a session goes to Login, not Home', (
    tester,
  ) async {
    final repository = _DeferredAuthRepository();
    final controller = AuthController(repository);
    await pumpPhone(tester, controller);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);

    repository.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Quick Access'), findsNothing);
    expect(find.textContaining('Huda Latheef'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _DeferredAuthRepository implements AuthRepository {
  final Completer<Attendee?> _restore = Completer<Attendee?>();

  void complete(Attendee? attendee) {
    _restore.complete(attendee);
  }

  @override
  String? get accessToken => null;

  @override
  Future<Attendee?> restoreSession() => _restore.future;

  @override
  Future<Attendee> updateProfile({
    required String fullName,
    required String organization,
    required String phone,
  }) async {
    throw const AuthException('Not used in startup tests.');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Attendee> signIn({
    required String email,
    required String password,
  }) async {
    throw const AuthException('Sign-in is not used in startup tests.');
  }

  @override
  Future<Attendee> register(RegistrationDraft draft) async {
    throw const AuthException('Register is not used in startup tests.');
  }
}
