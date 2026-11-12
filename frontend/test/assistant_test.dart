import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ntam_congress_demo/app/theme/app_theme.dart';
import 'package:ntam_congress_demo/features/assistant/assistant_answer_text.dart';
import 'package:ntam_congress_demo/features/assistant/assistant_screen.dart';
import 'package:ntam_congress_demo/features/assistant/catalog_lookup.dart';
import 'package:ntam_congress_demo/features/assistant/data/assistant_models.dart';
import 'package:ntam_congress_demo/features/assistant/data/assistant_repository.dart';
import 'package:ntam_congress_demo/features/assistant/data/http_assistant_repository.dart';

class _FakeAssistantRepository implements AssistantRepository {
  _FakeAssistantRepository(this._onAsk);

  final Future<AssistantReply> Function(String question) _onAsk;
  final questions = <String>[];

  @override
  Future<AssistantReply> ask(String question) {
    questions.add(question);
    return _onAsk(question);
  }
}

void main() {
  test('AssistantReply ignores incomplete source objects', () {
    final reply = AssistantReply.fromJson({
      'answer': 'Hall B',
      'grounded': true,
      'sources': [
        {'type': 'session', 'id': 'pediatric'},
        {'type': 'session'},
        {'id': 'sarah'},
        'ignore',
      ],
    });
    expect(reply.sources, hasLength(1));
    expect(reply.sources.single.type, 'session');
    expect(reply.sources.single.id, 'pediatric');
  });

  test('catalog lookup only resolves existing session and speaker ids', () {
    expect(catalogSession('pediatric')?.title, 'Future of Pediatric Nutrition');
    expect(catalogSession('not-real'), isNull);
    expect(catalogSpeaker('sarah')?.fullName, 'Dr. Sarah Johnson');
    expect(catalogSpeaker('invented'), isNull);
    expect(
      canOpenSource(const AssistantSource(type: 'session', id: 'pediatric')),
      isTrue,
    );
    expect(
      canOpenSource(const AssistantSource(type: 'session', id: 'invented')),
      isFalse,
    );
  });

  test('HttpAssistantRepository parses a grounded reply', () async {
    final repository = HttpAssistantRepository(
      baseUrl: 'http://10.0.2.2:3000',
      post:
          ({
            required uri,
            required headers,
            required body,
            required timeout,
          }) async {
            expect(uri.path, '/api/assistant/ask');
            expect(body, contains('Pediatric Nutrition'));
            return const AssistantHttpResponse(
              statusCode: 200,
              body:
                  '{"answer":"Dr. Sarah Johnson.","grounded":true,"sources":[{"type":"session","id":"pediatric"},{"type":"speaker","id":"sarah"}]}',
            );
          },
    );

    final reply = await repository.ask(
      'Who is speaking at Future of Pediatric Nutrition?',
    );
    expect(reply.grounded, isTrue);
    expect(reply.answer, contains('Sarah Johnson'));
    expect(reply.sources.map((source) => source.id).toList(), [
      'pediatric',
      'sarah',
    ]);
  });

  test('HttpAssistantRepository maps 504 to a timeout error', () async {
    final repository = HttpAssistantRepository(
      post:
          ({
            required uri,
            required headers,
            required body,
            required timeout,
          }) async {
            return const AssistantHttpResponse(
              statusCode: 504,
              body: '{"error":"The assistant timed out.","code":"timeout"}',
            );
          },
    );

    expect(
      () => repository.ask('When is the opening ceremony?'),
      throwsA(
        isA<AssistantException>().having(
          (error) => error.kind,
          'kind',
          AssistantFailureKind.timeout,
        ),
      ),
    );
  });

  testWidgets('Congress AI empty state lists suggested questions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _assistantApp(
        _FakeAssistantRepository(
          (_) async => const AssistantReply(
            answer: 'unused',
            grounded: false,
            sources: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Congress AI'), findsOneWidget);
    expect(find.text('Ask about this congress'), findsOneWidget);
    expect(
      find.text('Who is speaking at Future of Pediatric Nutrition?'),
      findsOneWidget,
    );
  });

  test('assistant answer spans render markdown bold and keep line breaks', () {
    final spans = assistantAnswerSpans(
      '**Session:** Future of Pediatric Nutrition\n**Time:** 10:30 AM\n**Location:** Hall B\n**Speaker:** Dr. Sarah Johnson',
    );
    final plain = spans.map((span) => span.text ?? '').join();
    expect(plain, isNot(contains('**')));
    expect(
      plain,
      'Session: Future of Pediatric Nutrition\nTime: 10:30 AM\nLocation: Hall B\nSpeaker: Dr. Sarah Johnson',
    );
    expect(
      spans
          .where((span) => span.style?.fontWeight == FontWeight.w700)
          .map((span) => span.text)
          .toList(),
      ['Session:', 'Time:', 'Location:', 'Speaker:'],
    );
  });

  testWidgets('Congress AI shows a mocked answer and catalog source chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _assistantApp(
        _FakeAssistantRepository((question) async {
          expect(question, contains('Pediatric Nutrition'));
          return const AssistantReply(
            answer: 'Dr. Sarah Johnson presents in Hall B.',
            grounded: true,
            sources: [
              AssistantSource(type: 'session', id: 'pediatric'),
              AssistantSource(type: 'session', id: 'invented'),
            ],
          );
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Who is speaking at Future of Pediatric Nutrition?'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dr. Sarah Johnson presents in Hall B.'), findsOneWidget);
    expect(find.text('Future of Pediatric Nutrition'), findsWidgets);
    expect(find.text('invented'), findsNothing);
  });

  testWidgets('Congress AI answer bubble renders markdown bold labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _assistantApp(
        _FakeAssistantRepository((_) async {
          return const AssistantReply(
            answer:
                '**Session:** Future of Pediatric Nutrition\n**Speaker:** Dr. Sarah Johnson',
            grounded: true,
            sources: [AssistantSource(type: 'session', id: 'pediatric')],
          );
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Who is speaking at Future of Pediatric Nutrition?'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('Session:'), findsOneWidget);
    expect(find.textContaining('Dr. Sarah Johnson'), findsOneWidget);

    final answer = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) => widget.text.toPlainText().contains('Session:'));
    expect(answer.text.toPlainText().contains('**'), isFalse);
    expect(
      answer.text.toPlainText(),
      contains('Session: Future of Pediatric Nutrition'),
    );
    expect(answer.text.toPlainText(), contains('\nSpeaker: Dr. Sarah Johnson'));

    bool hasBold(InlineSpan span, String label) {
      if (span is TextSpan) {
        if (span.text == label &&
            (span.style?.fontWeight?.value ?? 0) >= FontWeight.w700.value) {
          return true;
        }
        return span.children?.any((child) => hasBold(child, label)) ?? false;
      }
      return false;
    }

    expect(hasBold(answer.text, 'Session:'), isTrue);
    expect(hasBold(answer.text, 'Speaker:'), isTrue);
  });

  test('authenticated assistant request forwards Supabase bearer token', () async {
    final repository = HttpAssistantRepository(
      tokenProvider: () => 'test-access-token',
      post: ({
        required uri,
        required headers,
        required body,
        required timeout,
      }) async {
        expect(uri.path, '/api/assistant/ask');
        expect(headers['Authorization'], 'Bearer test-access-token');
        expect(body, contains('mobile number'));
        return const AssistantHttpResponse(
          statusCode: 200,
          body: '{"answer":"Your saved phone is +971 50 123 4567.","grounded":true,"sources":[]}',
        );
      },
    );
    final reply = await repository.ask('What is my mobile number?');
    expect(reply.answer, contains('+971 50 123 4567'));
    expect(reply.grounded, true);
  });

  testWidgets('personal questions reach the backend AI instead of local canned answers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = _FakeAssistantRepository((question) async {
      expect(question, 'my mobile number?');
      return const AssistantReply(
        answer: 'Your phone number is from your saved attendee profile.',
        grounded: true,
        sources: [],
      );
    });
    await tester.pumpWidget(_assistantApp(repository));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ask about the programme'),
      'my mobile number?',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(repository.questions, ['my mobile number?']);
    expect(find.textContaining('Your phone number is from'), findsOneWidget);
    expect(find.textContaining('not stored on this attendee'), findsNothing);
  });

  testWidgets('Congress AI error state offers retry', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var fail = true;
    await tester.pumpWidget(
      _assistantApp(
        _FakeAssistantRepository((question) async {
          if (fail) {
            throw const AssistantException(
              'Cannot reach the congress API. Check Wi-Fi and that the backend is running.',
              kind: AssistantFailureKind.offline,
            );
          }
          return const AssistantReply(
            answer: 'Opening Ceremony is at 08:30 AM.',
            grounded: true,
            sources: [AssistantSource(type: 'session', id: 'opening')],
          );
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('When is the opening ceremony?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Cannot reach the congress API'),
      findsOneWidget,
    );

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Opening Ceremony is at 08:30 AM.'), findsOneWidget);
  });
}

Widget _assistantApp(AssistantRepository repository) {
  return MaterialApp.router(
    theme: AppTheme.congress(),
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => AssistantScreen(repository: repository),
        ),
      ],
    ),
  );
}
