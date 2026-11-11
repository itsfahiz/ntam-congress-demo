import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../../app/api_config.dart';
import '../../congress/domain/congress_models.dart';
import 'questions_repository.dart';

class HttpQuestionsRepository implements QuestionsRepository {
  HttpQuestionsRepository({
    required this.tokenProvider,
    String? baseUrl,
    this.timeout = const Duration(seconds: 20),
  }) : baseUrl = _trimBase(baseUrl ?? ApiConfig.baseUrl);

  final String Function() tokenProvider;
  final String baseUrl;
  final Duration timeout;

  static String _trimBase(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  @override
  Future<List<CongressQuestion>> list() async {
    final json = await _send('GET', '/api/questions');
    final raw = json['questions'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) _fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<CongressQuestion> create({
    required String body,
    required QuestionTopic topic,
    required String authorName,
  }) async {
    final json = await _send(
      'POST',
      '/api/questions',
      body: {'body': body.trim(), 'topic': topic.name},
    );
    final question = json['question'];
    if (question is! Map) {
      throw const QuestionsException('The question was not saved. Try again.');
    }
    return _fromJson(Map<String, dynamic>.from(question));
  }

  @override
  Future<CongressQuestion> like(String questionId) {
    return _requestQuestion('POST', '/api/questions/$questionId/like');
  }

  @override
  Future<CongressQuestion> unlike(String questionId) {
    return _requestQuestion('DELETE', '/api/questions/$questionId/like');
  }

  @override
  Future<List<QuestionReply>> listReplies(String questionId) async {
    final json = await _send('GET', '/api/questions/$questionId/replies');
    final raw = json['replies'];
    if (raw is! List) return const [];
    final replies = <QuestionReply>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final reply = QuestionReply.fromMap(Map<String, dynamic>.from(item));
      if (reply != null) replies.add(reply);
    }
    return replies;
  }

  @override
  Future<QuestionReply> createReply({
    required String questionId,
    required String body,
  }) async {
    final json = await _send(
      'POST',
      '/api/questions/$questionId/replies',
      body: {'body': body.trim()},
    );
    final reply = json['reply'];
    if (reply is! Map) {
      throw const QuestionsException('The reply was not saved. Try again.');
    }
    final parsed = QuestionReply.fromMap(Map<String, dynamic>.from(reply));
    if (parsed == null) {
      throw const QuestionsException('The reply was not saved. Try again.');
    }
    return parsed;
  }

  Future<CongressQuestion> _requestQuestion(String method, String path) async {
    final json = await _send(method, path);
    final question = json['question'];
    if (question is! Map) {
      throw const QuestionsException('Could not update the question. Try again.');
    }
    return _fromJson(Map<String, dynamic>.from(question));
  }

  CongressQuestion _fromJson(Map<String, dynamic> json) {
    return CongressQuestion(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      topic: _topicFrom(json['topic'] as String?),
      authorName: json['authorName'] as String? ?? 'Attendee',
      seedLikes: 0,
      answered: json['answered'] == true,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  QuestionTopic _topicFrom(String? value) {
    return QuestionTopic.values.firstWhere(
      (topic) => topic.name == value,
      orElse: () => QuestionTopic.general,
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = tokenProvider();
    if (token.isEmpty) {
      throw const QuestionsException('Sign in to load live questions.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = switch (method) {
        'GET' => await client.getUrl(uri).timeout(timeout),
        'POST' => await client.postUrl(uri).timeout(timeout),
        'DELETE' => await client.deleteUrl(uri).timeout(timeout),
        _ => throw const QuestionsException(
          'Could not reach the question board. Try again.',
        ),
      };
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'application/json');
      if (body != null) {
        request.headers.set('Content-Type', 'application/json');
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(timeout);
      final raw = await utf8.decodeStream(response).timeout(timeout);
      Map<String, dynamic> json = const {};
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) json = Map<String, dynamic>.from(decoded);
      } on FormatException {
        json = const {};
      }

      if (response.statusCode == 401) {
        throw const QuestionsException('Sign in again to load live questions.');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      throw QuestionsException(
        (json['error'] as String?) ??
            'Could not reach the question board. Try again.',
      );
    } on QuestionsException {
      rethrow;
    } on TimeoutException {
      throw const QuestionsException(
        'The question board timed out. Try again.',
      );
    } on SocketException {
      throw const QuestionsException(
        'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class QuestionsScope extends InheritedWidget {
  const QuestionsScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final QuestionsRepository repository;

  static QuestionsRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<QuestionsScope>();
    assert(scope != null, 'QuestionsScope not found in the widget tree.');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(QuestionsScope oldWidget) {
    return repository != oldWidget.repository;
  }
}
