import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/qa/qa_board.dart';
import 'package:ntam_congress_demo/features/congress/domain/congress_models.dart';
import 'package:ntam_congress_demo/features/voting/data/mock_polls_repository.dart';
import 'package:ntam_congress_demo/features/voting/data/polls_repository.dart';

import 'support/home_shortcuts.dart';

void main() {
  group('MockPollsRepository', () {
    test('records one vote and rejects a duplicate for the same poll', () async {
      final repository = MockPollsRepository();
      expect((await repository.getActive()).myOptionId, isNull);

      final voted = await repository.vote(
        pollId: MockPollsRepository.pollId,
        optionId: MockPollsRepository.aiId,
      );
      expect(voted.myOptionId, MockPollsRepository.aiId);
      expect(voted.totalVotes, 1);
      expect(
        voted.options
            .firstWhere((option) => option.id == MockPollsRepository.aiId)
            .percent,
        100,
      );

      expect(
        () => repository.vote(
          pollId: MockPollsRepository.pollId,
          optionId: MockPollsRepository.digitalId,
        ),
        throwsA(
          isA<PollsException>().having(
            (error) => error.alreadyVoted,
            'alreadyVoted',
            isTrue,
          ),
        ),
      );
      expect((await repository.getActive()).myOptionId, MockPollsRepository.aiId);
    });

    test('allows one vote on each poll independently', () async {
      final repository = MockPollsRepository();
      await repository.vote(
        pollId: MockPollsRepository.pollId,
        optionId: MockPollsRepository.aiId,
      );
      final second = await repository.vote(
        pollId: MockPollsRepository.poll2Id,
        optionId: MockPollsRepository.pediatricId,
      );
      expect(second.id, MockPollsRepository.poll2Id);
      expect(second.myOptionId, MockPollsRepository.pediatricId);

      final listed = await repository.list();
      expect(listed, hasLength(3));
      expect(listed[0].myOptionId, MockPollsRepository.aiId);
      expect(listed[1].myOptionId, MockPollsRepository.pediatricId);
      expect(listed[2].myOptionId, isNull);
    });

    test('rejects an option that is not on the poll', () async {
      final repository = MockPollsRepository();
      expect(
        () => repository.vote(
          pollId: MockPollsRepository.pollId,
          optionId: 'not-an-option',
        ),
        throwsA(isA<PollsException>()),
      );
    });
  });

  group('QaBoard', () {
    test('rejects empty, short, and over-limit questions', () {
      final board = QaBoard();
      expect(board.validate(''), 'Enter a question before submitting.');
      expect(
        board.validate('Too short'),
        'Add a bit more detail (at least ${QaBoard.minLength} characters).',
      );
      expect(
        board.validate('x' * (QaBoard.maxLength + 1)),
        'Keep questions to ${QaBoard.maxLength} characters.',
      );
    });

    test('shows only API questions and ignores catalog samples', () {
      const fromApi = CongressQuestion(
        id: 'api-huda',
        body: 'How does this session apply in clinic today?',
        topic: QuestionTopic.nutrition,
        authorName: 'Huda Latheef',
        seedLikes: 0,
      );
      final board = QaBoard();
      board.replaceSubmitted([fromApi]);

      expect(board.visible, hasLength(1));
      expect(board.visible.single.id, 'api-huda');
      expect(board.visible.single.localSubmission, isFalse);
      expect(
        board.visible.any((question) => question.id == 'q-growth'),
        isFalse,
      );
      expect(
        board.visible.any(
          (question) => question.body.contains('pediatric nutrition plans'),
        ),
        isFalse,
      );

      board.sort = QuestionSort.popular;
      expect(board.visible.single.id, 'api-huda');

      board.sort = QuestionSort.answered;
      expect(board.visible, isEmpty);

      final popular = CongressQuestion(
        id: 'api-popular',
        body: 'Which endpoints matter most at the bedside?',
        topic: QuestionTopic.research,
        authorName: 'Amira Hassan',
        seedLikes: 0,
        likeCount: 3,
        createdAt: DateTime(2026, 11, 11, 9),
      );
      const answered = CongressQuestion(
        id: 'api-answered',
        body: 'Will the closing keynote include both congress days?',
        topic: QuestionTopic.general,
        authorName: 'Congress Committee',
        seedLikes: 0,
        answered: true,
      );
      board.replaceSubmitted([
        fromApi.copyWith(likeCount: 1),
        popular,
        answered,
      ]);
      board.sort = QuestionSort.popular;
      expect(board.visible.map((question) => question.id).toList(), [
        'api-popular',
        'api-huda',
        'api-answered',
      ]);
      board.sort = QuestionSort.answered;
      expect(board.visible.single.id, 'api-answered');
    });
  });

  Future<void> pumpPhoneApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const CongressApp());
    await tester.pumpAndSettle();
  }

  Future<void> signInAsDemo(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email'),
      'huda@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your password'),
      'congress',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  Future<void> dismissSnackBar(WidgetTester tester) async {
    final messenger = ScaffoldMessenger.maybeOf(
      tester.element(find.byType(SnackBar)),
    );
    messenger?.hideCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  testWidgets('Live Voting submits once and then shows live results', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tapHomeShortcut(tester, 'Voting');

    expect(find.text('Live Voting'), findsOneWidget);
    expect(
      find.text('Which innovation will have the greatest impact on healthcare?'),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Artificial Intelligence'), findsOneWidget);
    expect(find.text('Personalized Nutrition'), findsOneWidget);
    expect(find.text('Digital Health'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('submit-vote')));
    await tester.pump();
    expect(find.text('Choose an answer to vote.'), findsOneWidget);

    final aiOption = find.byKey(
      const ValueKey('poll-option-${MockPollsRepository.aiId}'),
    );
    await tester.ensureVisible(aiOption);
    await tester.pumpAndSettle();
    await tester.tap(aiOption);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-vote')));
    await tester.pumpAndSettle();

    expect(find.text('VOTED'), findsOneWidget);
    expect(find.text('Live results'), findsOneWidget);
    expect(find.text('Simulated results'), findsNothing);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('1 vote'), findsOneWidget);
    expect(find.text('Next Poll'), findsOneWidget);
    expect(find.text('Submit Vote'), findsNothing);
    await dismissSnackBar(tester);

    await tester.tap(find.text('Next Poll'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Which topic would you most like to explore at a future medical congress?',
      ),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('Pediatric Nutrition'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous poll'));
    await tester.pumpAndSettle();
    expect(find.text('VOTED'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(
      find.text('Which innovation will have the greatest impact on healthcare?'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tapHomeShortcut(tester, 'Voting');
    expect(find.text('VOTED'), findsOneWidget);
    expect(find.text('Artificial Intelligence'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('Live Voting shows a loading skeleton before polls arrive', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CongressApp(
        pollsRepository: _DelayedPollsRepository(
          delay: const Duration(milliseconds: 600),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Voting', settle: false);

    expect(find.text('Live Voting'), findsOneWidget);
    expect(find.text('Audience Interaction'), findsOneWidget);
    expect(find.text('Loading live polls…'), findsOneWidget);
    expect(find.text('Submit Vote'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(
      find.text('Which innovation will have the greatest impact on healthcare?'),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Loading live polls…'), findsNothing);
    expect(
      find.text('Which innovation will have the greatest impact on healthcare?'),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);
  });

  testWidgets('Live Voting shows a retryable error when polls fail to load', (
    tester,
  ) async {
    final repository = _FlakyPollsRepository();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CongressApp(pollsRepository: repository));
    await tester.pumpAndSettle();
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Voting');

    expect(find.text('Could not load live polls'), findsOneWidget);
    expect(find.text('Could not load the live poll. Try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('Which innovation will have the greatest impact on healthcare?'),
      findsNothing,
    );

    repository.fail = false;
    await tester.tap(find.byKey(const ValueKey('retry-polls')));
    await tester.pumpAndSettle();

    expect(find.text('Could not load live polls'), findsNothing);
    expect(
      find.text('Which innovation will have the greatest impact on healthcare?'),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('Ask Q&A validates then keeps a persisted submission', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await tapHomeShortcut(tester, 'Ask Q&A');

    expect(find.text('Ask the Experts'), findsOneWidget);
    expect(find.textContaining('pediatric nutrition plans'), findsNothing);
    expect(find.text('On this device'), findsNothing);
    expect(find.text('No questions in this view yet.'), findsOneWidget);

    await tester.tap(find.text('Submit Question'));
    await tester.pump();
    expect(find.text('Enter a question before submitting.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Type your question for the speaker...'),
      'Short',
    );
    await tester.tap(find.text('Submit Question'));
    await tester.pump();
    expect(find.textContaining('at least 12 characters'), findsOneWidget);

    const question = 'How does this session apply in clinic today?';
    await tester.enterText(
      find.widgetWithText(TextField, 'Type your question for the speaker...'),
      question,
    );
    await tester.tap(find.text('Nutrition').first);
    await tester.pump();
    await tester.tap(find.text('Submit Question'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text(question), findsOneWidget);
    expect(find.text('On this device'), findsNothing);
    expect(find.text('local'), findsNothing);
    expect(find.textContaining('Huda Latheef'), findsWidgets);
    expect(find.text('Nutrition'), findsWidgets);
    expect(find.textContaining('pediatric nutrition plans'), findsNothing);
    await dismissSnackBar(tester);

    await tester.tap(find.text('Popular'));
    await tester.pump();
    expect(find.text(question), findsOneWidget);
    expect(find.text('Popularity is not available yet.'), findsNothing);

    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
    expect(find.byTooltip('Remove like'), findsOneWidget);

    await tester.tap(find.text('Answered'));
    await tester.pump();
    expect(find.text('No answered questions yet.'), findsOneWidget);

    await tester.tap(find.text('Recent'));
    await tester.pump();
    expect(find.text(question), findsOneWidget);

    await tester.ensureVisible(find.text('Reply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(find.text('No replies yet.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Write a reply...'),
      'Bedside application needs a clear protocol.',
    );
    final sendReply = find.widgetWithText(TextButton, 'Send reply');
    await tester.ensureVisible(sendReply);
    await tester.pumpAndSettle();
    await tester.tap(sendReply);
    await tester.pumpAndSettle();
    expect(find.text('Bedside application needs a clear protocol.'), findsOneWidget);
    expect(find.text('1 reply'), findsOneWidget);
    expect(find.text('On this device'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tapHomeShortcut(tester, 'Ask Q&A');
    expect(find.text(question), findsOneWidget);
    expect(find.textContaining('Huda Latheef'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.text('1 reply'), findsOneWidget);
    expect(find.text('On this device'), findsNothing);
  });

  testWidgets('Ask Q&A keeps composer and submit above the keyboard', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await tapHomeShortcut(tester, 'Ask Q&A');

    await tester.tap(
      find.widgetWithText(TextField, 'Type your question for the speaker...'),
    );
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 1008);
    await tester.pumpAndSettle();

    expect(find.text('Write your question'), findsOneWidget);
    expect(find.text('Submit Question'), findsOneWidget);

    final viewHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final keyboardTop = viewHeight - 1008 / tester.view.devicePixelRatio;
    expect(
      tester.getRect(find.text('Write your question')).top,
      lessThan(keyboardTop),
    );
    expect(
      tester.getRect(find.text('Submit Question')).bottom,
      lessThanOrEqualTo(keyboardTop + 0.5),
    );
  });
}

class _DelayedPollsRepository implements PollsRepository {
  _DelayedPollsRepository({required this.delay});

  final Duration delay;
  final MockPollsRepository _inner = MockPollsRepository();

  @override
  Future<List<LivePoll>> list() async {
    await Future<void>.delayed(delay);
    return _inner.list();
  }

  @override
  Future<LivePoll> getActive() => _inner.getActive();

  @override
  Future<LivePoll> vote({required String pollId, required String optionId}) {
    return _inner.vote(pollId: pollId, optionId: optionId);
  }
}

class _FlakyPollsRepository implements PollsRepository {
  var fail = true;
  final MockPollsRepository _inner = MockPollsRepository();

  @override
  Future<List<LivePoll>> list() async {
    if (fail) {
      throw const PollsException('Could not load the live poll. Try again.');
    }
    return _inner.list();
  }

  @override
  Future<LivePoll> getActive() => _inner.getActive();

  @override
  Future<LivePoll> vote({required String pollId, required String optionId}) {
    return _inner.vote(pollId: pollId, optionId: optionId);
  }
}
