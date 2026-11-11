import '../domain/attendee.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
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
  Future<Attendee> signIn({required String email, required String password});

  /// Creates a local in-memory attendee. This is not a real Nestlé account.
  Future<Attendee> register(RegistrationDraft draft);
}
