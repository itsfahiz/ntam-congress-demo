import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../domain/attendee.dart';

enum AuthLifecycle { restoring, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    restoreSession();
  }

  final AuthRepository _repository;

  Attendee? _attendee;
  bool _loading = false;
  bool _restoring = true;
  String? _error;

  Attendee? get attendee => _attendee;
  bool get isSignedIn => _attendee != null;
  bool get isLoading => _loading;
  bool get isRestoring => _restoring;
  String? get error => _error;
  String? get accessToken => _repository.accessToken;

  AuthLifecycle get lifecycle {
    if (_restoring) return AuthLifecycle.restoring;
    if (_attendee != null) return AuthLifecycle.authenticated;
    return AuthLifecycle.unauthenticated;
  }

  Future<void> restoreSession() async {
    if (!_restoring) {
      _restoring = true;
      notifyListeners();
    }
    try {
      _attendee = await _repository.restoreSession();
    } catch (_) {
      _attendee = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<void> register(RegistrationDraft draft) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _attendee = await _repository.register(draft);
    } on EmailConfirmationRequiredException {
      _attendee = null;
      _error = null;
      rethrow;
    } on AuthException catch (error) {
      _error = error.message;
      rethrow;
    } catch (_) {
      _error = 'Unable to continue. Please try again.';
      throw const AuthException('Unable to continue. Please try again.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _run(Future<Attendee> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _attendee = await action();
    } on AuthException catch (error) {
      _error = error.message;
      rethrow;
    } catch (_) {
      _error = 'Unable to continue. Please try again.';
      throw const AuthException('Unable to continue. Please try again.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _attendee = null;
    _error = null;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in the widget tree.');
    return scope!.notifier!;
  }
}
