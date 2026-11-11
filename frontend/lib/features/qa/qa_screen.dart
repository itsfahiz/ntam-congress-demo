import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Question added')));
  }

  @override
  Widget build(BuildContext context) {
    final questions = _board.visible;
    final remaining = QaBoard.maxLength - _questionController.text.length;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return CongressFeatureScaffold(
      title: 'Ask Q&A',
      titleAlign: TextAlign.start,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
      leading: CongressHeaderButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        outlined: true,
        onPressed: () => context.pop(),
      ),
      trailing: CongressHeaderButton(
        icon: Icons.forum_rounded,
        tooltip: 'Write a question',
        outlined: true,
        foreground: AppColors.gold,
        onPressed: _focusComposer,
      ),
      hero: keyboardOpen
          ? null
          : const CongressHeroBanner(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Ask the Experts',
              subtitle: 'Submit your questions and vote for top discussions',
              padding: EdgeInsets.fromLTRB(18, 20, 18, 20),
              titleSize: 20,
              titleWeight: FontWeight.w900,
              badgeSize: 56,
              titleSpacing: 8,
              contentSpacing: 16,
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, keyboardOpen ? 12 : 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    focusNode: _questionFocus,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: QaBoard.maxLength,
                    textInputAction: TextInputAction.newline,
                    scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                    onChanged: (_) => setState(() => _error = null),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    cursorColor: AppColors.accentBlue,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Type your question for the speaker...',
                      counterText: '$remaining characters left',
                      filled: true,
                      fillColor: const Color(0xFFF4F6FB),
                      contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.fieldBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.fieldBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: CongressFilterChips<QuestionTopic>(
                      selected: _topic,
                      onSelected: (value) => setState(
                        () => _topic = value ?? QuestionTopic.general,
                      ),
                      options: const [
                        FilterChipOption(
                          value: QuestionTopic.general,
                          label: 'General',
                        ),
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
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _submitKey,
                    child: GradientButton(
                      label: 'Submit Question',
                      icon: Icons.send_rounded,
                      showArrow: false,
                      gradient: AppColors.createAccountButton,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SortTabs(
            selected: _board.sort,
            onSelected: (value) => setState(() => _board.sort = value),
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
                  message: 'Replies are not sent to speakers.',
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _SortTabs extends StatelessWidget {
  const _SortTabs({required this.selected, required this.onSelected});

  final QuestionSort selected;
  final ValueChanged<QuestionSort> onSelected;

  static const _options = <(QuestionSort, String)>[
    (QuestionSort.popular, 'Popular'),
    (QuestionSort.recent, 'Recent'),
    (QuestionSort.answered, 'Answered'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _SortTab(
              label: _options[i].$2,
              selected: selected == _options[i].$1,
              onTap: () => onSelected(_options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _SortTab extends StatelessWidget {
  const _SortTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectedGold = Color(0xFFF6D06A);

    return Material(
      color: selected ? selectedGold : AppColors.fieldFill,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: selected ? selectedGold : AppColors.fieldBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.navyDeep : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
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
    final highlighted = question.answered || question.localSubmission;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? AppColors.gold.withValues(alpha: 0.55)
              : AppColors.fieldBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UpvoteControl(likes: likes, liked: liked, onLike: onLike),
              const SizedBox(width: 12),
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
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InitialsAvatar(
                initials: initials.isEmpty ? 'NA' : initials,
                size: 26,
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
                    height: 1.2,
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
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 26),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpvoteControl extends StatelessWidget {
  const _UpvoteControl({
    required this.likes,
    required this.liked,
    required this.onLike,
  });

  final int likes;
  final bool liked;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Local like',
      child: Material(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Column(
              children: [
                Icon(
                  liked
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_up_outlined,
                  color: liked ? AppColors.accentBlue : AppColors.textSecondary,
                ),
                Text(
                  '$likes',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
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
