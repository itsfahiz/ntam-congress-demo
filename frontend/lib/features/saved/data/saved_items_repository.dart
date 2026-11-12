class SavedItemsException implements Exception {
  const SavedItemsException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Persistence operations: HTTP implementation uses the Supabase JWT on the API.
/// accountKey is only for grouping the isolated widget-test fixture and is
/// never trusted by the backend as a user identifier.
abstract interface class SavedItemsRepository {
  Future<Set<String>> load(String accountKey);
  Future<void> save(String accountKey, String type, String itemId);
  Future<void> remove(String accountKey, String type, String itemId);
}
