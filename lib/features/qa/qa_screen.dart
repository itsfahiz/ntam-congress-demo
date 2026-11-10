import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/demo_limitation_sheet.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/initials_avatar.dart';
import '../auth/state/auth_controller.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import 'qa_board.dart';

class QaScreen extends StatefulWidget {
  const QaScreen({super.key});

  @override
  State<QaScreen> createState() => _QaScreenState();
}

class _QaScreenState extends State<QaScreen> {
  final _questionController = TextEditingController();
  final _questionFocus = FocusNode();
  final _composerKey = GlobalKey();
  final _submitKey = GlobalKey();
  late final QaBoard _board;
  var _topic = QuestionTopic.general;
  String? _error;

  @override
  void initState() {
    super.initState();
    _board = QaBoard(seeded: CongressCatalog.questions);
    _questionFocus.addListener(_onComposerFocus);
  }

  @override
  void dispose() {
    _questionFocus.removeListener(_onComposerFocus);
    _questionController.dispose();
    _questionFocus.dispose();
    super.dispose();
  }

  void _onComposerFocus() {
    setState(() {});
    if (_questionFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureComposerVisible();
      });
    }
  }

  void _focusComposer() {
    _questionFocus.requestFocus();
    _ensureComposerVisible();
  }

  void _ensureComposerVisible() {
    final context = _submitKey.currentContext ?? _composerKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      alignment: 1,
    );
  }

  void _submit() {
    final attendee = AuthScope.of(context).attendee;
    final author = attendee?.fullName ?? 'Attendee';
    final error = _board.validate(_questionController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _board.submit(
        body: _questionController.text,
        topic: _topic,
        authorName: author,
      );
      _questionController.clear();
    });
    _questionFocus.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Question saved on this device. It was not sent to a speaker or server.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _board.visible;
    final remaining = QaBoard.maxLength - _questionController.text.length;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return CongressFeatureScaffold(
      title: 'Ask Q&A',
      trailing: CongressGoldHeaderButton(
        icon: Icons.chat_bubble_outline_rounded,
        tooltip: 'Write a question',
        onPressed: _focusComposer,
      ),
      hero: keyboardOpen
          ? null
          : const CongressHeroBanner(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Ask the Experts',
              subtitle: 'Submit your questions and vote for top discussions',
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            'Write your question',
            key: _composerKey,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            focusNode: _questionFocus,
            minLines: 3,
            maxLines: 5,
            maxLength: QaBoard.maxLength,
            textInputAction: TextInputAction.newline,
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
            onChanged: (_) => setState(() => _error = null),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.35,
            ),
            cursorColor: AppColors.accentBlue,
            decoration: InputDecoration(
              hintText: 'Type your question for the speaker...',
              counterText: '$remaining characters left',
              filled: true,
              fillColor: AppColors.searchFill,
              contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CongressFilterChips<QuestionTopic>(
            selected: _topic,
            onSelected: (value) =>
                setState(() => _topic = value ?? QuestionTopic.general),
            options: const [
              FilterChipOption(value: QuestionTopic.general, label: 'General'),
              FilterChipOption(
                value: QuestionTopic.nutrition,
                label: 'Nutrition',
              ),
              FilterChipOption(
                value: QuestionTopic.research,
                label: 'Research',
              ),
              FilterChipOption(
                value: QuestionTopic.clinical,
                label: 'Clinical',
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          KeyedSubtree(
            key: _submitKey,
            child: GradientButton(
              label: 'Submit Question',
              icon: Icons.play_arrow_rounded,
              showArrow: false,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'New questions stay on this device. Seeded cards below are demo copy, not a live audience feed.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          CongressFilterChips<QuestionSort>(
            selected: _board.sort,
            accent: ChipAccent.gold,
            onSelected: (value) =>
                setState(() => _board.sort = value ?? QuestionSort.recent),
            options: const [
              FilterChipOption(value: QuestionSort.popular, label: 'Popular'),
              FilterChipOption(value: QuestionSort.recent, label: 'Recent'),
              FilterChipOption(value: QuestionSort.answered, label: 'Answered'),
            ],
          ),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No questions in this view yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final question in questions) ...[
              _QuestionCard(
                question: question,
                likes: _board.likesFor(question),
                liked: _board.likedIds.contains(question.id),
                onLike: () => setState(() => _board.toggleLike(question.id)),
                onReply: () => showDemoLimitationSheet(
                  context,
                  title: 'Replies are not connected',
                  message:
                      'This assessment app does not send replies to speakers or a moderation queue.',
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.likes,
    required this.liked,
    required this.onLike,
    required this.onReply,
  });

  final CongressQuestion question;
  final int likes;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final initials = question.authorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .where(
          (part) => !RegExp(r'^dr\.?$', caseSensitive: false).hasMatch(part),
        )
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: question.localSubmission
              ? AppColors.gold
              : AppColors.fieldBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  IconButton(
                    tooltip: 'Local like',
                    onPressed: onLike,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      liked
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_up_outlined,
                      color: liked
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$likes',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          label: question.topicLabel,
                          background: AppColors.talkWash,
                          foreground: AppColors.navyChip,
                        ),
                        if (question.answered)
                          const _Pill(
                            label: 'Answered',
                            background: AppColors.ceremonyWash,
                            foreground: AppColors.categoryInk,
                          ),
                        if (question.localSubmission)
                          const _Pill(
                            label: 'On this device',
                            background: AppColors.ceremonyWash,
                            foreground: AppColors.categoryInk,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.body,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InitialsAvatar(
                initials: initials.isEmpty ? 'NA' : initials,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.localSubmission
                      ? '${question.authorName} · local'
                      : question.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
