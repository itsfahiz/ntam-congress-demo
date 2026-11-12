import 'saved_items_repository.dart';

/// Test fixture only. The real app uses HttpSavedItemsRepository (PostgreSQL).
class MockSavedItemsRepository implements SavedItemsRepository {
  final Map<String, Set<String>> _byAccount = {};

  @override
  Future<Set<String>> load(String accountKey) async =>
      Set<String>.of(_byAccount[accountKey] ?? <String>{});

  @override
  Future<void> save(String accountKey, String type, String itemId) async {
    _byAccount.putIfAbsent(accountKey, () => <String>{}).add('$type:$itemId');
  }

  @override
  Future<void> remove(String accountKey, String type, String itemId) async {
    _byAccount[accountKey]?.remove('$type:$itemId');
  }
}
