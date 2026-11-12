import '../domain/attendee.dart';
import 'auth_repository.dart';

class UnconfiguredAuthRepository implements AuthRepository {
  static const _message =
      'Supabase Auth is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.';

  @override
  String? get accessToken => null;

  @override
  Future<Attendee?> restoreSession() async => null;

  @override
  Future<Attendee> signIn({required String email, required String password}) {
    throw const AuthException(_message);
  }

  @override
  Future<Attendee> register(RegistrationDraft draft) {
    throw const AuthException(_message);
  }

  @override
  Future<Attendee> updateProfile({
    required String fullName,
    required String organization,
    required String phone,
  }) {
    throw const AuthException(_message);
  }

  @override
  Future<void> signOut() async {}
}
