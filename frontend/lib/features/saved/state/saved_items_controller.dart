import 'package:flutter/material.dart';

import '../data/saved_items_repository.dart';

class SavedItemsController extends ChangeNotifier {
  SavedItemsController(this._repository);

  final SavedItemsRepository _repository;
  String? _accountKey;
  Set<String> _keys = <String>{};
  final Set<String> _pending = <String>{};
  bool _loading = false;
  bool _disposed = false;
  String? _error;
  int _generation = 0;

  bool get isLoading => _loading;
  String? get error => _error;
  int get count => _keys.length;
  int countFor(String type) => _keys.where((key) => key.startsWith('$type:')).length;
  Set<String> idsFor(String type) => _keys
      .where((key) => key.startsWith('$type:'))
      .map((key) => key.substring(type.length + 1))
      .toSet();
  bool isSaved(String type, String id) => _keys.contains('$type:$id');

  /// A new account clears all visible state before any async request returns.
  Future<void> loadFor(String? accountKey) async {
    if (accountKey == _accountKey) return;
    _generation++;
    _accountKey = accountKey;
    _keys = <String>{};
    _pending.clear();
    _loading = false;
    _error = null;
    notifyListeners();
    if (accountKey != null) await reload();
  }

  Future<void> reload() async {
    final account = _accountKey;
    if (account == null) return;
    final generation = _generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final keys = await _repository.load(account);
      if (_disposed || generation != _generation) return;
      _keys = keys;
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _error = error.toString();
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// The visual bookmark changes only after PostgreSQL confirms the operation.
  Future<void> toggle(String type, String id) async {
    final account = _accountKey;
    if (account == null) {
      throw const SavedItemsException('Sign in to manage saved items.');
    }
    if (_loading || _error != null) {
      throw const SavedItemsException(
        'Saved items are not loaded. Try again.',
      );
    }
    final key = '$type:$id';
    if (!_pending.add(key)) return;
    final generation = _generation;
    final wasSaved = _keys.contains(key);
    notifyListeners();
    try {
      if (wasSaved) {
        await _repository.remove(account, type, id);
      } else {
        await _repository.save(account, type, id);
      }
      if (_disposed || generation != _generation) return;
      if (wasSaved) {
        _keys.remove(key);
      } else {
        _keys.add(key);
      }
      notifyListeners();
    } finally {
      if (!_disposed && generation == _generation) {
        _pending.remove(key);
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

class SavedItemsScope extends InheritedNotifier<SavedItemsController> {
  const SavedItemsScope({
    super.key,
    required SavedItemsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SavedItemsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SavedItemsScope>();
    assert(scope != null, 'SavedItemsScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
