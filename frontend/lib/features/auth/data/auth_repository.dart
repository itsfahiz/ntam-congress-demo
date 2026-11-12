import '../domain/attendee.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Sign-up succeeded, but Supabase still requires email confirmation.
/// The attendee is not authenticated until they verify and sign in.
class EmailConfirmationRequiredException extends AuthException {
  const EmailConfirmationRequiredException({this.email})
    : super(
        'Account created. Check your email to confirm before signing in.',
      );

  final String? email;
}

class RegistrationDraft {
  const RegistrationDraft({
    required this.fullName,
    required this.email,
    required this.organization,
    required this.password,
  });

  final String fullName;
  final String email;
  final String organization;
  final String password;
}

abstract interface class AuthRepository {
  String? get accessToken;

  Future<Attendee?> restoreSession();

  Future<Attendee> signIn({required String email, required String password});

  Future<Attendee> register(RegistrationDraft draft);

  Future<Attendee> updateProfile({
    required String fullName,
    required String organization,
    required String phone,
  });

  Future<void> signOut();
}
