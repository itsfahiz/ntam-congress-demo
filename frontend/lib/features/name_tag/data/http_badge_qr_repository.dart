import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/api_config.dart';
import 'badge_qr_repository.dart';

class BadgeQrHttpResponse {
  const BadgeQrHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

typedef BadgeQrHttpGet =
    Future<BadgeQrHttpResponse> Function({
      required Uri uri,
      required Map<String, String> headers,
      required Duration timeout,
    });

class HttpBadgeQrRepository implements BadgeQrRepository {
  HttpBadgeQrRepository({
    required this.tokenProvider,
    String? baseUrl,
    BadgeQrHttpGet? get,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = _trimBase(baseUrl ?? ApiConfig.baseUrl),
       _get = get ?? getWithHttpClient;

  final String Function() tokenProvider;
  final String baseUrl;
  final Duration timeout;
  final BadgeQrHttpGet _get;

  static final _badgeId = RegExp(r'^NMC-[A-Z0-9-]{1,32}$');
  static final _signature = RegExp(r'^[a-fA-F0-9]{64}$');

  static String _trimBase(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Future<BadgeQrHttpResponse> getWithHttpClient({
    required Uri uri,
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(timeout);
      final body = await utf8.decodeStream(response).timeout(timeout);
      return BadgeQrHttpResponse(statusCode: response.statusCode, body: body);
    } on TimeoutException {
      throw const BadgeQrException(
        'Loading your verification badge timed out. Try again.',
      );
    } on SocketException {
      throw const BadgeQrException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } on HandshakeException {
      throw const BadgeQrException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } finally {
      client.close(force: true);
    }
  }

  static bool isSignedVerifyUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.path != '/badge/verify') return false;
    final badgeId = uri.queryParameters['b'] ?? '';
    final signature = uri.queryParameters['s'] ?? '';
    return _badgeId.hasMatch(badgeId) && _signature.hasMatch(signature);
  }

  @override
  Future<String> issueVerifyUrl() async {
    final token = tokenProvider();
    if (token.isEmpty) {
      throw const BadgeQrException('Sign in to load your verification badge.');
    }

    late final BadgeQrHttpResponse response;
    try {
      response = await _get(
        uri: Uri.parse('$baseUrl/api/me/badge'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        timeout: timeout,
      );
    } on BadgeQrException {
      rethrow;
    } on TimeoutException {
      throw const BadgeQrException(
        'Loading your verification badge timed out. Try again.',
      );
    } on SocketException {
      throw const BadgeQrException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    }

    Map<String, dynamic> json = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) json = Map<String, dynamic>.from(decoded);
    } on FormatException {
      json = const {};
    }

    if (response.statusCode == 401) {
      throw const BadgeQrException(
        'Sign in again to load your verification badge.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BadgeQrException(
        (json['error'] as String?) ??
            'Could not load your verification badge. Try again.',
      );
    }

    final verifyUrl = json['verifyUrl'] as String? ?? '';
    if (!isSignedVerifyUrl(verifyUrl)) {
      throw const BadgeQrException(
        'Could not load your verification badge. Try again.',
      );
    }
    return verifyUrl;
  }
}
