import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/data/assistant_repository.dart';
import '../features/assistant/data/http_assistant_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/name_tag/data/badge_qr_repository.dart';
import '../features/name_tag/data/mock_badge_qr_repository.dart';
import '../features/qa/data/http_questions_repository.dart';
import '../features/qa/data/mock_questions_repository.dart';
import '../features/qa/data/questions_repository.dart';
import '../features/voting/data/mock_polls_repository.dart';
import '../features/voting/data/polls_repository.dart';
import '../features/saved/data/mock_saved_items_repository.dart';
import '../features/saved/data/saved_items_repository.dart';
import '../features/saved/state/saved_items_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class CongressApp extends StatefulWidget {
  const CongressApp({
    super.key,
    this.authController,
    this.assistantRepository,
    this.questionsRepository,
    this.badgeQrRepository,
    this.pollsRepository,
    this.savedItemsRepository,
  });

  final AuthController? authController;
  final AssistantRepository? assistantRepository;
  final QuestionsRepository? questionsRepository;
  final BadgeQrRepository? badgeQrRepository;
  final PollsRepository? pollsRepository;
  final SavedItemsRepository? savedItemsRepository;

  @override
  State<CongressApp> createState() => _CongressAppState();
}

class _CongressAppState extends State<CongressApp> {
  late final AuthController _authController;
  late final AssistantRepository _assistantRepository;
  late final QuestionsRepository _questionsRepository;
  late final BadgeQrRepository _badgeQrRepository;
  late final PollsRepository _pollsRepository;
  late final bool _ownsAuthController;
  late final SavedItemsController _savedController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController =
        widget.authController ?? AuthController(MockAuthRepository());
    _assistantRepository =
        widget.assistantRepository ?? HttpAssistantRepository(
          tokenProvider: () => _authController.accessToken ?? '',
        );
    _questionsRepository =
        widget.questionsRepository ?? MockQuestionsRepository();
    _badgeQrRepository =
        widget.badgeQrRepository ??
        MockBadgeQrRepository(
          badgeIdProvider: () => _authController.attendee?.id ?? '',
        );
    _pollsRepository = widget.pollsRepository ?? MockPollsRepository();
    _savedController = SavedItemsController(
      widget.savedItemsRepository ?? MockSavedItemsRepository(),
    );
    _authController.addListener(_handleAccountChange);
    _handleAccountChange();
    _router = createRouter(_authController);
  }

  void _handleAccountChange() {
    final account = _authController.attendee?.email;
    _savedController.loadFor(account);
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAccountChange);
    _savedController.dispose();
    _router.dispose();
    if (_ownsAuthController) {
      _authController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: SavedItemsScope(
        controller: _savedController,
        child: AssistantScope(
        repository: _assistantRepository,
        child: QuestionsScope(
          repository: _questionsRepository,
          child: BadgeQrScope(
            repository: _badgeQrRepository,
            child: PollsScope(
              repository: _pollsRepository,
              child: MaterialApp.router(
                title: 'Nestlé Medical Congress',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.congress(),
                routerConfig: _router,
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
