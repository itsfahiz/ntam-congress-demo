import '../../congress/domain/congress_models.dart';

class QuestionsException implements Exception {
  const QuestionsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuestionReply {
  const QuestionReply({
    required this.id,
    required this.questionId,
    required this.body,
    required this.authorName,
    this.createdAt,
  });

  final String id;
  final String questionId;
  final String body;
  final String authorName;
  final DateTime? createdAt;

  static QuestionReply? fromMap(Map<dynamic, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    if (id.isEmpty || body.isEmpty) return null;
    return QuestionReply(
      id: id,
      questionId: json['questionId'] as String? ?? '',
      body: body,
      authorName: json['authorName'] as String? ?? 'Attendee',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

abstract interface class QuestionsRepository {
  Future<List<CongressQuestion>> list();

  Future<CongressQuestion> create({
    required String body,
    required QuestionTopic topic,
    required String authorName,
  });

  Future<CongressQuestion> like(String questionId);

  Future<CongressQuestion> unlike(String questionId);

  Future<List<QuestionReply>> listReplies(String questionId);

  Future<QuestionReply> createReply({
    required String questionId,
    required String body,
  });
}
