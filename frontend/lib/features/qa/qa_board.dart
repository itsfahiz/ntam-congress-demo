import '../congress/domain/congress_models.dart';

class QaBoard {
  QaBoard();

  static const minLength = 12;
  static const maxLength = 240;
  static const replyMinLength = 2;
  static const replyMaxLength = 240;

  final List<CongressQuestion> submitted = [];
  var sort = QuestionSort.recent;

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

  String? validateReply(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Enter a reply before submitting.';
    if (text.length < replyMinLength) {
      return 'Add a bit more detail (at least $replyMinLength characters).';
    }
    if (text.length > replyMaxLength) {
      return 'Keep replies to $replyMaxLength characters.';
    }
    return null;
  }

  void replaceSubmitted(List<CongressQuestion> questions) {
    submitted
      ..clear()
      ..addAll(questions);
  }

  void addRemote(CongressQuestion question) {
    submitted.removeWhere((item) => item.id == question.id);
    submitted.insert(0, question);
    sort = QuestionSort.recent;
  }

  void replaceOne(CongressQuestion question) {
    final index = submitted.indexWhere((item) => item.id == question.id);
    if (index >= 0) {
      submitted[index] = question;
      return;
    }
    submitted.insert(0, question);
  }

  List<CongressQuestion> get visible {
    switch (sort) {
      case QuestionSort.popular:
        final items = List<CongressQuestion>.from(submitted);
        items.sort((a, b) {
          final likes = b.likeCount.compareTo(a.likeCount);
          if (likes != 0) return likes;
          return _createdAt(b).compareTo(_createdAt(a));
        });
        return items;
      case QuestionSort.recent:
        return List<CongressQuestion>.from(submitted);
      case QuestionSort.answered:
        return [
          for (final question in submitted)
            if (question.answered) question,
        ];
    }
  }

  int _createdAt(CongressQuestion question) {
    return question.createdAt?.millisecondsSinceEpoch ?? 0;
  }
}
