import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/api_config.dart';
import 'saved_items_repository.dart';

class HttpSavedItemsRepository implements SavedItemsRepository {
  HttpSavedItemsRepository({
    required this.tokenProvider,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final String Function() tokenProvider;
  final String _baseUrl;
  final Duration timeout;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? body,
  }) async {
    final token = tokenProvider();
    if (token.isEmpty) {
      throw const SavedItemsException('Sign in to manage saved items.');
    }
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final request = await client.openUrl(method, uri).timeout(timeout);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'application/json');
      if (body != null) {
        request.headers.set('Content-Type', 'application/json');
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(timeout);
      final raw = await utf8.decodeStream(response).timeout(timeout);
      Map<String, dynamic> payload;
      try {
        final value = jsonDecode(raw);
        payload = value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{};
      } on FormatException {
        payload = <String, dynamic>{};
      }
      if (response.statusCode == 401) {
        throw const SavedItemsException('Session expired. Sign in again.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SavedItemsException(
          (payload['error'] as String?) ?? 'Could not update saved items.',
        );
      }
      return payload;
    } on TimeoutException {
      throw const SavedItemsException('Saved items request timed out.');
    } on SocketException {
      throw const SavedItemsException('Cannot reach the congress API.');
    } on HandshakeException {
      throw const SavedItemsException('Cannot establish a secure connection.');
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<Set<String>> load(String accountKey) async {
    final payload = await _request('GET', '/api/saved');
    final items = payload['items'];
    if (items is! List) {
      throw const SavedItemsException('Could not read saved items.');
    }
    final keys = <String>{};
    for (final item in items) {
      if (item is! Map) continue;
      final type = item['itemType'];
      final id = item['itemId'];
      if ((type == 'session' || type == 'resource') &&
          id is String && id.isNotEmpty) {
        keys.add('$type:$id');
      }
    }
    return keys;
  }

  @override
  Future<void> save(String accountKey, String type, String itemId) async {
    await _request(
      'POST',
      '/api/saved',
      body: {'itemType': type, 'itemId': itemId},
    );
  }

  @override
  Future<void> remove(String accountKey, String type, String itemId) async {
    await _request(
      'DELETE',
      '/api/saved/${Uri.encodeComponent(type)}/${Uri.encodeComponent(itemId)}',
    );
  }
}
