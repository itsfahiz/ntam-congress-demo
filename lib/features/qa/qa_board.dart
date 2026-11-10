import '../congress/domain/congress_models.dart';

class QaBoard {
  QaBoard({required List<CongressQuestion> seeded})
    : _seeded = List<CongressQuestion>.from(seeded);

  static const minLength = 12;
  static const maxLength = 240;

  final List<CongressQuestion> _seeded;
  final List<CongressQuestion> submitted = [];
  final Set<String> likedIds = {};
  var sort = QuestionSort.recent;
  var _nextId = 1;

  String? validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Enter a question before submitting.';
    if (text.length < minLength) {
      return 'Add a bit more detail (at least $minLength characters).';
    }
    if (text.length > maxLength) {
      return 'Keep questions to $maxLength characters.';
    }
    return null;
  }

  CongressQuestion? submit({
    required String body,
    required QuestionTopic topic,
    required String authorName,
  }) {
    if (validate(body) != null) return null;
    final question = CongressQuestion(
      id: 'local-$_nextId',
      body: body.trim(),
      topic: topic,
      authorName: authorName,
      seedLikes: 0,
      localSubmission: true,
    );
    _nextId += 1;
    submitted.insert(0, question);
    sort = QuestionSort.recent;
    return question;
  }

  void toggleLike(String id) {
    if (!likedIds.add(id)) {
      likedIds.remove(id);
    }
  }

  int likesFor(CongressQuestion question) {
    final extra = likedIds.contains(question.id) ? 1 : 0;
    return question.seedLikes + extra;
  }

  List<CongressQuestion> get visible {
    var items = <CongressQuestion>[...submitted, ..._seeded];
    if (sort == QuestionSort.answered) {
      items = items.where((question) => question.answered).toList();
    }
    switch (sort) {
      case QuestionSort.popular:
        items.sort((a, b) => likesFor(b).compareTo(likesFor(a)));
      case QuestionSort.recent:
        break;
      case QuestionSort.answered:
        items.sort((a, b) => likesFor(b).compareTo(likesFor(a)));
    }
    return items;
  }
}
