import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/app/congress_app.dart';
import 'package:ntam_congress_demo/features/congress/data/congress_catalog.dart';
import 'package:ntam_congress_demo/features/qa/qa_board.dart';
import 'package:ntam_congress_demo/features/voting/voting_board.dart';
import 'package:ntam_congress_demo/features/congress/domain/congress_models.dart';

void main() {
  group('VotingBoard', () {
    VotingBoard board() => VotingBoard(CongressCatalog.polls);

    test('requires a selection before recording a vote', () {
      final voting = board();
      expect(voting.submit(), VoteCastResult.missingSelection);
      expect(voting.hasVotedCurrent, isFalse);
    });

    test('records one vote and rejects a duplicate for the same poll', () {
      final voting = board();
      voting.select('very-good');
      expect(voting.submit(), VoteCastResult.recorded);
      expect(voting.hasVotedCurrent, isTrue);
      expect(voting.submit(), VoteCastResult.alreadyVoted);
      expect(voting.selectedOptionId, 'very-good');
    });

    test('adds the local vote to simulated counts only', () {
      final voting = board();
      final poll = voting.current;
      final option = poll.options.firstWhere((item) => item.id == 'very-good');
      final before = voting.simulatedCount(poll, option);

      voting.select('very-good');
      voting.submit();

      expect(voting.simulatedCount(poll, option), before + 1);
      expect(
        voting.simulatedTotal(poll),
        poll.options.fold<int>(0, (sum, item) => sum + item.simulatedVotes) + 1,
      );
    });

    test('reset clears votes so the poll can be answered again', () {
      final voting = board();
      voting.select('excellent');
      voting.submit();
      voting.nextPoll();
      voting.select('pediatric');
      voting.submit();

      voting.reset();

      expect(voting.index, 0);
      expect(voting.hasVotedCurrent, isFalse);
      expect(voting.submit(), VoteCastResult.missingSelection);
    });
  });

  group('QaBoard', () {
    test('rejects empty, short, and over-limit questions', () {
      final board = QaBoard(seeded: CongressCatalog.questions);
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

    test('keeps local submissions separate from seeded cards', () {
      final board = QaBoard(seeded: CongressCatalog.questions);
      final submitted = board.submit(
        body: 'How does this session apply in clinic today?',
        topic: QuestionTopic.nutrition,
        authorName: 'Amira Hassan',
      );

      expect(submitted, isNotNull);
      expect(submitted!.localSubmission, isTrue);
      expect(submitted.answered, isFalse);
      expect(board.visible.first.id, submitted.id);
      expect(
        board.visible.where((question) => question.id == 'q-growth'),
        isNotEmpty,
      );
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

  Future<void> openFromQuickAccess(
    WidgetTester tester,
    String description,
  ) async {
    await tester.tap(find.text('View All').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(description),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(description));
    await tester.pumpAndSettle();
  }

  Future<void> dismissSnackBar(WidgetTester tester) async {
    final messenger = ScaffoldMessenger.maybeOf(
      tester.element(find.byType(SnackBar)),
    );
    messenger?.hideCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  testWidgets('Live Voting submits once and then shows simulated results', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await openFromQuickAccess(tester, 'Join live audience polls');

    expect(find.text('Live Voting'), findsOneWidget);
    expect(
      find.text('How would you rate the current session?'),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('submit-vote')));
    await tester.pump();
    expect(find.text('Choose an answer to vote.'), findsOneWidget);

    await tester.tap(find.text('Very Good'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('submit-vote')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('VOTED'), findsOneWidget);
    expect(find.text('Simulated results'), findsOneWidget);
    expect(find.text('Next Poll'), findsOneWidget);
    expect(find.text('Submit Vote'), findsNothing);
    await dismissSnackBar(tester);

    await tester.tap(find.text('Next Poll'));
    await tester.pumpAndSettle();
    expect(
      find.text('Which topic should the next workshop expand?'),
      findsOneWidget,
    );
    expect(find.text('OPEN'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous poll'));
    await tester.pumpAndSettle();
    expect(find.text('VOTED'), findsOneWidget);

    await tester.tap(find.byTooltip('Reset demo votes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('Submit Vote'), findsOneWidget);
    await dismissSnackBar(tester);
  });

  testWidgets('Ask Q&A validates then keeps a local submission', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);

    await openFromQuickAccess(tester, 'Submit questions to speakers');

    expect(find.text('Ask the Experts'), findsOneWidget);
    expect(find.textContaining('pediatric nutrition plans'), findsOneWidget);

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

    expect(find.text(question), findsOneWidget);
    expect(find.text('On this device'), findsOneWidget);
    expect(find.textContaining('Huda Latheef'), findsWidgets);
    expect(
      find.textContaining('pediatric nutrition plans', skipOffstage: false),
      findsOneWidget,
    );
    await dismissSnackBar(tester);
  });

  testWidgets('Ask Q&A keeps composer and submit above the keyboard', (
    tester,
  ) async {
    await pumpPhoneApp(tester);
    await signInAsDemo(tester);
    await openFromQuickAccess(tester, 'Submit questions to speakers');

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
