import '../domain/attendee.dart';
import 'auth_repository.dart';

class _StoredAccount {
  const _StoredAccount({required this.password, required this.attendee});

  final String password;
  final Attendee attendee;
}

/// In-memory auth used for the assessment demo. Nothing is sent to a server.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _accounts[demoAttendee.email] = _StoredAccount(
      password: demoPassword,
      attendee: demoAttendee,
    );
  }

  static const demoPassword = 'congress';
  static const demoAttendee = Attendee(
    id: 'NMC-2026-001',
    fullName: 'Huda Latheef',
    email: 'huda@example.com',
    role: 'Medical Congress Attendee',
    organization: 'NTAM',
    phone: '+971 56 283 4212',
    location: 'Dubai, UAE',
  );

  final Map<String, _StoredAccount> _accounts = {};
  var _nextBadge = 2;

  @override
  Future<Attendee> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final normalized = email.trim().toLowerCase();
    final account = _accounts[normalized];
    if (account == null) {
      throw const AuthException('No attendee profile found for that email.');
    }
    if (account.password != password) {
      throw const AuthException('Incorrect password.');
    }
    return account.attendee;
  }

  @override
  Future<Attendee> register(RegistrationDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final email = draft.email.trim().toLowerCase();
    if (_accounts.containsKey(email)) {
      throw const AuthException(
        'An attendee profile already exists for that email.',
      );
    }

    final attendee = Attendee(
      id: 'NMC-2026-${_nextBadge.toString().padLeft(3, '0')}',
      fullName: draft.fullName.trim(),
      email: email,
      role: 'Medical Congress Attendee',
      organization: draft.organization.trim(),
      phone: 'Not provided',
      location: 'Dubai, UAE',
    );
    _nextBadge += 1;
    _accounts[email] = _StoredAccount(
      password: draft.password,
      attendee: attendee,
    );
    return attendee;
  }
}
