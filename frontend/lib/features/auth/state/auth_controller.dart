import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import '../domain/attendee.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  Attendee? _attendee;
  bool _loading = false;
  String? _error;

  Attendee? get attendee => _attendee;
  bool get isSignedIn => _attendee != null;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> signIn({required String email, required String password}) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<void> register(RegistrationDraft draft) {
    return _run(() => _repository.register(draft));
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

  void signOut() {
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
