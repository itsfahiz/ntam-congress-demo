import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../../app/api_config.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';

class AssistantHttpResponse {
  const AssistantHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

typedef AssistantHttpPost =
    Future<AssistantHttpResponse> Function({
      required Uri uri,
      required Map<String, String> headers,
      required String body,
      required Duration timeout,
    });

class HttpAssistantRepository implements AssistantRepository {
  HttpAssistantRepository({
    String? baseUrl,
    AssistantHttpPost? post,
    this.tokenProvider,
    this.timeout = const Duration(seconds: 50),
  }) : baseUrl = _trimBase(baseUrl ?? ApiConfig.baseUrl),
       _post = post ?? postWithHttpClient;

  final String baseUrl;
  final String Function()? tokenProvider;
  final AssistantHttpPost _post;
  final Duration timeout;

  static String _trimBase(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Future<AssistantHttpResponse> postWithHttpClient({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      request.add(utf8.encode(body));
      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(response).timeout(timeout);
      return AssistantHttpResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } on TimeoutException {
      throw const AssistantException(
        'The assistant is taking too long. Try again.',
        kind: AssistantFailureKind.timeout,
      );
    } on SocketException {
      throw const AssistantException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
        kind: AssistantFailureKind.offline,
      );
    } on HandshakeException {
      throw const AssistantException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
        kind: AssistantFailureKind.offline,
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<AssistantReply> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.length < 2 || trimmed.length > 500) {
      throw const AssistantException(
        'Ask a short congress question (2–500 characters).',
        kind: AssistantFailureKind.invalid,
      );
    }

    late final AssistantHttpResponse response;
    try {
      final token = tokenProvider?.call() ?? '';
      response = await _post(
        uri: Uri.parse('$baseUrl/api/assistant/ask'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'question': trimmed}),
        timeout: timeout,
      );
    } on AssistantException {
      rethrow;
    } on TimeoutException {
      throw const AssistantException(
        'The assistant is taking too long. Try again.',
        kind: AssistantFailureKind.timeout,
      );
    } on SocketException {
      throw const AssistantException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
        kind: AssistantFailureKind.offline,
      );
    } catch (_) {
      throw const AssistantException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
        kind: AssistantFailureKind.offline,
      );
    }

    return _parse(response);
  }

  AssistantReply _parse(AssistantHttpResponse response) {
    Map<String, dynamic> json = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      json = const {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final reply = AssistantReply.fromJson(json);
      if (reply.answer.trim().isEmpty) {
        throw const AssistantException(
          'The assistant returned an empty answer. Try another question.',
        );
      }
      return reply;
    }

    final serverMessage = json['error'] as String?;
    final code = json['code'] as String?;
    throw AssistantException(
      _messageForStatus(response.statusCode, serverMessage, code),
      kind: _kindForStatus(response.statusCode, code),
    );
  }

  static AssistantFailureKind _kindForStatus(int status, String? code) {
    if (code == 'timeout' || status == 504) return AssistantFailureKind.timeout;
    if (code == 'quota' || status == 429) return AssistantFailureKind.busy;
    if (status == 400) return AssistantFailureKind.invalid;
    return AssistantFailureKind.unavailable;
  }

  static String _messageForStatus(int status, String? serverMessage, String? code) {
    if (code == 'timeout' || status == 504) {
      return 'The assistant is taking too long. Try again.';
    }
    if (code == 'quota' || status == 429) {
      return serverMessage ?? 'The assistant is busy. Try again shortly.';
    }
    if (status == 400) {
      return 'Ask a short congress question (2–500 characters).';
    }
    if (status == 401) {
      return 'Sign in again to ask Congress AI.';
    }
    if (serverMessage != null &&
        serverMessage.isNotEmpty &&
        !serverMessage.toLowerCase().contains('key') &&
        !serverMessage.toLowerCase().contains('gemini')) {
      return serverMessage;
    }
    return 'The assistant is temporarily unavailable. Try again shortly.';
  }
}

class AssistantScope extends InheritedWidget {
  const AssistantScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final AssistantRepository repository;

  static AssistantRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AssistantScope>();
    assert(scope != null, 'AssistantScope not found in the widget tree.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(AssistantScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
