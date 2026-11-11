import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../app/api_config.dart';
import 'polls_repository.dart';

class PollsHttpResponse {
  const PollsHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

typedef PollsHttpSend =
    Future<PollsHttpResponse> Function({
      required String method,
      required Uri uri,
      required Map<String, String> headers,
      String? body,
      required Duration timeout,
    });

class HttpPollsRepository implements PollsRepository {
  HttpPollsRepository({
    required this.tokenProvider,
    String? baseUrl,
    PollsHttpSend? send,
    this.timeout = const Duration(seconds: 20),
  }) : baseUrl = _trimBase(baseUrl ?? ApiConfig.baseUrl),
       _send = send ?? sendWithHttpClient;

  final String Function() tokenProvider;
  final String baseUrl;
  final Duration timeout;
  final PollsHttpSend _send;

  static String _trimBase(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Future<PollsHttpResponse> sendWithHttpClient({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
    required Duration timeout,
  }) async {
    final client = HttpClient();
    try {
      final request = method == 'GET'
          ? await client.getUrl(uri).timeout(timeout)
          : await client.postUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      if (body != null) request.add(utf8.encode(body));
      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(response).timeout(timeout);
      return PollsHttpResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } on TimeoutException {
      throw const PollsException('Loading the live poll timed out. Try again.');
    } on SocketException {
      throw const PollsException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } on HandshakeException {
      throw const PollsException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<List<LivePoll>> list() async {
    final json = await _sendJson('GET', '/api/polls');
    final polls = LivePoll.listFromJson(json);
    if (polls.isEmpty) {
      throw const PollsException('No active poll.');
    }
    return polls;
  }

  @override
  Future<LivePoll> getActive() {
    return _requestPoll('GET', '/api/polls/active');
  }

  @override
  Future<LivePoll> vote({required String pollId, required String optionId}) {
    return _requestPoll(
      'POST',
      '/api/polls/$pollId/vote',
      body: {'optionId': optionId},
    );
  }

  Future<LivePoll> _requestPoll(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final json = await _sendJson(method, path, body: body);
    final poll = LivePoll.fromJson(json);
    if (poll == null) {
      throw const PollsException('Could not load the live poll. Try again.');
    }
    return poll;
  }

  Future<Map<String, dynamic>> _sendJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = tokenProvider();
    if (token.isEmpty) {
      throw const PollsException('Sign in to load the live poll.');
    }

    late final PollsHttpResponse response;
    try {
      response = await _send(
        method: method,
        uri: Uri.parse('$baseUrl$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          if (body != null) 'Content-Type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
        timeout: timeout,
      );
    } on PollsException {
      rethrow;
    } on TimeoutException {
      throw const PollsException('Loading the live poll timed out. Try again.');
    } on SocketException {
      throw const PollsException(
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
      throw const PollsException('Sign in again to load the live poll.');
    }
    if (response.statusCode == 409) {
      throw PollsException(
        (json['error'] as String?) ?? 'You already voted in this poll.',
        alreadyVoted: true,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PollsException(
        (json['error'] as String?) ?? 'Could not load the live poll. Try again.',
      );
    }
    return json;
  }
}
