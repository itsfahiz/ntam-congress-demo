import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ntam_congress_demo/app/app_routes.dart';
import 'package:ntam_congress_demo/app/theme/app_theme.dart';
import 'package:ntam_congress_demo/features/assistant/assistant_answer_text.dart';
import 'package:ntam_congress_demo/features/assistant/assistant_local.dart';
import 'package:ntam_congress_demo/features/assistant/assistant_screen.dart';
import 'package:ntam_congress_demo/features/assistant/catalog_lookup.dart';
import 'package:ntam_congress_demo/features/assistant/data/assistant_models.dart';
import 'package:ntam_congress_demo/features/assistant/data/assistant_repository.dart';
import 'package:ntam_congress_demo/features/assistant/data/http_assistant_repository.dart';
import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/domain/attendee.dart';
import 'package:ntam_congress_demo/features/auth/state/auth_controller.dart';
import 'package:ntam_congress_demo/features/saved/data/mock_saved_items_repository.dart';
import 'package:ntam_congress_demo/features/saved/state/saved_items_controller.dart';

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

  test('local assistant answers name and email from the signed-in profile', () {
    const attendee = MockAuthRepository.demoAttendee;
    final name = localAssistantReply("What's my name?", attendee);
    expect(name, isNotNull);
    expect(name!.answer, contains('Huda Latheef'));
    expect(name.sources, isEmpty);

    final email = localAssistantReply("What's my email?", attendee);
    expect(email!.answer, contains('huda@example.com'));

    final both = localAssistantReply("What's my name/email?", attendee);
    expect(both!.answer, contains('Huda Latheef'));
    expect(both.answer, contains('huda@example.com'));
  });

  test('local assistant shows issued badge ID and View My Badge', () {
    final reply = localAssistantReply(
      "What's my attendee ID?",
      MockAuthRepository.demoAttendee,
    );
    expect(reply!.answer, contains('NMC-2026-001'));
    expect(reply.actions.single.route, AppRoutes.nameTag);
    expect(reply.actions.single.label, 'View My Badge');

    final qr = localAssistantReply(
      'Show my QR',
      MockAuthRepository.demoAttendee,
    );
    expect(qr!.actions.single.label, 'View My Badge');

    const noId = Attendee(
      id: '',
      fullName: 'Guest',
      email: 'guest@example.com',
      role: 'Medical Congress Attendee',
      organization: 'NTAM',
      phone: 'Not provided',
      location: 'Dubai, UAE',
    );
    final ticket = localAssistantReply('Where is my ticket?', noId);
    expect(ticket!.answer.contains('NMC-'), isFalse);
    expect(ticket.actions.single.route, AppRoutes.nameTag);
  });

  test('local assistant does not invent a phone number for my number', () {
    final reply = localAssistantReply(
      "What's my number?",
      MockAuthRepository.demoAttendee,
    );
    expect(reply!.answer, contains('NMC-2026-001'));
    expect(reply.answer, contains('+971 56 283 4212'));
  });

  test('local assistant shows the actual saved phone, organization and location', () {
    const attendee = MockAuthRepository.demoAttendee;
    final phone = localAssistantReply('my mobile number?', attendee);
    expect(phone?.answer, contains('+971 56 283 4212'));
    expect(phone?.answer, isNot(contains('not stored')));
    expect(phone?.actions.single.route, AppRoutes.profile);

    final organization = localAssistantReply('What is my organization?', attendee);
    expect(organization?.answer, contains('NTAM'));
    final location = localAssistantReply('Where am I based?', attendee);
    expect(location?.answer, contains('Dubai, UAE'));

    const withoutPhone = Attendee(
      id: 'NMC-01234',
      fullName: 'Example Attendee',
      email: 'test@example.com',
      role: 'Attendee',
      organization: 'Demo',
      phone: 'Not provided',
      location: 'Dubai, UAE',
    );
    expect(
      localAssistantReply('What is my phone number?', withoutPhone)?.answer,
      contains('No phone number is saved'),
    );
  });

  test('saved items responses reflect shared account state', () async {
    final controller = SavedItemsController(MockSavedItemsRepository());
    addTearDown(controller.dispose);
    await controller.loadFor('huda@example.com');
    await controller.toggle('session', 'opening');
    await controller.toggle('resource', 'programme');
    final reply = localAssistantReply(
      'What are my saved items?',
      MockAuthRepository.demoAttendee,
      savedItems: controller,
    );
    expect(reply?.answer, contains('1 saved session(s) and 1 saved resource(s)'));
    expect(reply?.answer, contains('Opening Ceremony'));
    expect(reply?.answer, contains('Congress Scientific Programme'));
    expect(reply?.actions.single.route, AppRoutes.saved);
  });

  test('phone questions about congress mobile features are not intercepted', () {
    expect(
      localAssistantReply(
        'What mobile applications are used at the congress?',
        MockAuthRepository.demoAttendee,
      ),
      isNull,
    );
  });

  test('local assistant offers agenda, badge and venue actions', () {
    const attendee = MockAuthRepository.demoAttendee;
    final attend = localAssistantReply('How do I attend?', attendee);
    expect(attend!.actions.map((action) => action.label).toList(), [
      'View Agenda',
      'View My Badge',
      'Venue/Directions',
    ]);

    final schedule = localAssistantReply('Show my schedule', attendee);
    expect(schedule!.actions.single.route, AppRoutes.agenda);

    final venue = localAssistantReply('Where is the venue?', attendee);
    expect(venue!.actions.single.route, AppRoutes.venue);
  });

  test('local assistant leaves catalog questions for Gemini', () {
    const attendee = MockAuthRepository.demoAttendee;
    expect(
      localAssistantReply(
        'Tell me about the pediatric nutrition session and its speaker.',
        attendee,
      ),
      isNull,
    );
    expect(
      localAssistantReply(
        'Where is the venue and what facilities are listed?',
        attendee,
      ),
      isNull,
    );
  });

  testWidgets('Congress AI View My Badge opens the Name Tag route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final auth = AuthController(MockAuthRepository());
    addTearDown(auth.dispose);
    final repository = _FakeAssistantRepository(
      (_) async =>
          throw StateError('Gemini should not run for badge questions'),
    );

    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: MaterialApp.router(
          theme: AppTheme.congress(),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    AssistantScreen(repository: repository),
              ),
              GoRoute(
                path: AppRoutes.nameTag,
                builder: (context, state) =>
                    const Scaffold(body: Text('Name Tag screen')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await auth.signIn(
        email: MockAuthRepository.demoAttendee.email,
        password: MockAuthRepository.demoPassword,
      );
    });
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ask about the programme'),
      'Show my QR',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(repository.questions, isEmpty);
    expect(find.text('View My Badge'), findsOneWidget);
    await tester.tap(find.text('View My Badge'));
    await tester.pumpAndSettle();
    expect(find.text('Name Tag screen'), findsOneWidget);
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
