import '../../congress/domain/congress_models.dart';
import 'questions_repository.dart';

class MockQuestionsRepository implements QuestionsRepository {
  MockQuestionsRepository();

  final List<CongressQuestion> _submitted = [];
  final Map<String, Set<String>> _likes = {};
  final Map<String, List<QuestionReply>> _replies = {};
  var _nextId = 1;
  var _nextReplyId = 1;
  static const currentUserId = 'mock-user';

  CongressQuestion _withCounts(CongressQuestion question) {
    final liked = _likes[question.id] ?? {};
    final replies = _replies[question.id] ?? const [];
    return question.withInteraction(
      likeCount: liked.length,
      likedByMe: liked.contains(currentUserId),
      replyCount: replies.length,
    );
  }

  CongressQuestion _require(String questionId) {
    for (final question in _submitted) {
      if (question.id == questionId) return question;
    }
    throw const QuestionsException('Question not found.');
  }

  @override
  Future<List<CongressQuestion>> list() async {
    return [for (final question in _submitted) _withCounts(question)];
  }

  @override
  Future<CongressQuestion> create({
    required String body,
    required QuestionTopic topic,
    required String authorName,
  }) async {
    final question = CongressQuestion(
      id: 'local-$_nextId',
      body: body.trim(),
      topic: topic,
      authorName: authorName,
      seedLikes: 0,
      createdAt: DateTime.now(),
    );
    _nextId += 1;
    _submitted.insert(0, question);
    return _withCounts(question);
  }

  @override
  Future<CongressQuestion> like(String questionId) async {
    final question = _require(questionId);
    final liked = _likes[questionId] ?? <String>{};
    liked.add(currentUserId);
    _likes[questionId] = liked;
    return _withCounts(question);
  }

  @override
  Future<CongressQuestion> unlike(String questionId) async {
    final question = _require(questionId);
    final liked = _likes[questionId] ?? <String>{};
    liked.remove(currentUserId);
    _likes[questionId] = liked;
    return _withCounts(question);
  }

  @override
  Future<List<QuestionReply>> listReplies(String questionId) async {
    _require(questionId);
    return List<QuestionReply>.from(_replies[questionId] ?? const []);
  }

  @override
  Future<QuestionReply> createReply({
    required String questionId,
    required String body,
  }) async {
    _require(questionId);
    final text = body.trim();
    if (text.length < 2 || text.length > 240) {
      throw const QuestionsException(
        'Keep replies between 2 and 240 characters.',
      );
    }
    final reply = QuestionReply(
      id: 'reply-$_nextReplyId',
      questionId: questionId,
      body: text,
      authorName: 'Huda Latheef',
      createdAt: DateTime.now(),
    );
    _nextReplyId += 1;
    _replies.putIfAbsent(questionId, () => []).add(reply);
    return reply;
  }
}
