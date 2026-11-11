import 'package:flutter_test/flutter_test.dart';
import 'package:ntam_congress_demo/features/auth/data/auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/data/unconfigured_auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/state/auth_controller.dart';
import 'package:ntam_congress_demo/features/congress/domain/congress_models.dart';
import 'package:ntam_congress_demo/features/qa/data/mock_questions_repository.dart';
import 'package:ntam_congress_demo/features/qa/qa_board.dart';

void main() {
  test('MockAuthRepository signs in the seeded attendee', () async {
    final auth = MockAuthRepository();
    final attendee = await auth.signIn(
      email: 'huda@example.com',
      password: 'congress',
    );
    expect(attendee.id, 'NMC-2026-001');
    expect(attendee.fullName, 'Huda Latheef');
    expect(auth.accessToken, isNull);
    expect(await auth.restoreSession(), isNull);
  });

  test('MockAuthRepository does not persist a session after sign-out', () async {
    final controller = AuthController(MockAuthRepository());
    await controller.restoreSession();
    expect(controller.isSignedIn, isFalse);

    await controller.signIn(email: 'huda@example.com', password: 'congress');
    expect(controller.isSignedIn, isTrue);

    await controller.signOut();
    expect(controller.isSignedIn, isFalse);
    expect(controller.attendee, isNull);
  });

  test('UnconfiguredAuthRepository fails honestly', () async {
    final auth = UnconfiguredAuthRepository();
    expect(
      () => auth.signIn(email: 'huda@example.com', password: 'congress'),
      throwsA(isA<AuthException>()),
    );
  });

  test('MockQuestionsRepository keeps submitted questions', () async {
    final repository = MockQuestionsRepository();
    expect(await repository.list(), isEmpty);

    final created = await repository.create(
      body: 'How does this session apply in clinic today?',
      topic: QuestionTopic.nutrition,
      authorName: 'Huda Latheef',
    );
    expect(created.localSubmission, isFalse);
    expect(created.answered, isFalse);

    final listed = await repository.list();
    expect(listed, hasLength(1));
    expect(listed.first.body, contains('clinic today'));
    expect(listed.first.authorName, 'Huda Latheef');
    expect(listed.first.topic, QuestionTopic.nutrition);

    final board = QaBoard();
    board.replaceSubmitted(listed);
    expect(board.visible.first.id, created.id);
    expect(board.visible, hasLength(1));
    expect(board.visible.first.likeCount, 0);
    expect(board.visible.first.likedByMe, isFalse);

    final liked = await repository.like(created.id);
    expect(liked.likeCount, 1);
    expect(liked.likedByMe, isTrue);
    expect((await repository.like(created.id)).likeCount, 1);
    expect((await repository.unlike(created.id)).likeCount, 0);

    final second = await repository.create(
      body: 'Which endpoints matter most at the bedside today?',
      topic: QuestionTopic.research,
      authorName: 'Amira Hassan',
    );
    await repository.like(second.id);
    await repository.like(second.id);
    board.replaceSubmitted(await repository.list());
    board.sort = QuestionSort.popular;
    expect(board.visible.first.id, second.id);

    final reply = await repository.createReply(
      questionId: created.id,
      body: 'Bedside application needs a clear protocol.',
    );
    expect(reply.authorName, 'Huda Latheef');
    expect(reply.body, contains('Bedside application'));
    final replies = await repository.listReplies(created.id);
    expect(replies, hasLength(1));
    expect(replies.first.createdAt, isNotNull);
    expect(
      (await repository.list())
          .firstWhere((question) => question.id == created.id)
          .replyCount,
      1,
    );
  });
}
