import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/initials_avatar.dart';
import '../auth/state/auth_controller.dart';
import '../congress/domain/congress_models.dart';
import 'data/http_questions_repository.dart';
import 'data/questions_repository.dart';
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
  final _replySendKey = GlobalKey();
  late final QaBoard _board;
  final _replyController = TextEditingController();
  var _topic = QuestionTopic.general;
  String? _error;
  String? _loadError;
  String? _replyError;
  String? _openRepliesId;
  String? _likingId;
  var _loading = false;
  var _submitting = false;
  var _replySubmitting = false;
  final _replies = <String, List<QuestionReply>>{};
  final _loadingReplies = <String>{};

  QuestionsRepository get _repository => QuestionsScope.of(context);

  @override
  void initState() {
    super.initState();
    _board = QaBoard();
    _questionFocus.addListener(_onComposerFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _questionFocus.removeListener(_onComposerFocus);
    _questionController.dispose();
    _replyController.dispose();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final questions = await _repository.list();
      if (!mounted) return;
      setState(() {
        _board.replaceSubmitted(questions);
        _loading = false;
      });
    } on QuestionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load live questions.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final attendee = AuthScope.of(context).attendee;
    final author = attendee?.fullName ?? 'Attendee';
    final error = _board.validate(_questionController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final question = await _repository.create(
        body: _questionController.text,
        topic: _topic,
        authorName: author,
      );
      if (!mounted) return;
      setState(() {
        _board.addRemote(question);
        _questionController.clear();
        _submitting = false;
      });
      _questionFocus.unfocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question added')));
    } on QuestionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'The question was not saved. Try again.';
        _submitting = false;
      });
    }
  }

  Future<void> _toggleLike(CongressQuestion question) async {
    if (_likingId != null) return;
    setState(() => _likingId = question.id);
    try {
      final updated = question.likedByMe
          ? await _repository.unlike(question.id)
          : await _repository.like(question.id);
      if (!mounted) return;
      setState(() {
        _board.replaceOne(updated);
        _likingId = null;
      });
    } on QuestionsException catch (error) {
      if (!mounted) return;
      setState(() => _likingId = null);
      _showNotice(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _likingId = null);
      _showNotice('Could not update the like. Try again.');
    }
  }

  Future<void> _toggleReplies(CongressQuestion question) async {
    if (_openRepliesId == question.id) {
      setState(() {
        _openRepliesId = null;
        _replyError = null;
      });
      return;
    }
    setState(() {
      _openRepliesId = question.id;
      _replyError = null;
      _replyController.clear();
    });
    await _loadReplies(question.id);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureReplyComposerVisible();
    });
  }

  void _ensureReplyComposerVisible() {
    final context = _replySendKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      alignment: 1,
    );
  }

  Future<void> _loadReplies(String questionId) async {
    setState(() => _loadingReplies.add(questionId));
    try {
      final replies = await _repository.listReplies(questionId);
      if (!mounted) return;
      setState(() {
        _replies[questionId] = replies;
        _loadingReplies.remove(questionId);
      });
    } on QuestionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReplies.remove(questionId);
        _replyError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingReplies.remove(questionId);
        _replyError = 'Could not load replies. Try again.';
      });
    }
  }

  Future<void> _submitReply(CongressQuestion question) async {
    if (_replySubmitting) return;
    final error = _board.validateReply(_replyController.text);
    if (error != null) {
      setState(() => _replyError = error);
      return;
    }
    setState(() {
      _replySubmitting = true;
      _replyError = null;
    });
    try {
      final reply = await _repository.createReply(
        questionId: question.id,
        body: _replyController.text,
      );
      if (!mounted) return;
      final existing = [...?_replies[question.id], reply];
      setState(() {
        _replies[question.id] = existing;
        _board.replaceOne(question.copyWith(replyCount: existing.length));
        _replyController.clear();
        _replySubmitting = false;
      });
    } on QuestionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _replySubmitting = false;
        _replyError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _replySubmitting = false;
        _replyError = 'The reply was not saved. Try again.';
      });
    }
  }

  void _showNotice(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
                      loading: _submitting,
                      gradient: AppColors.createAccountButton,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _loadError!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _SortTabs(
            selected: _board.sort,
            onSelected: (value) => setState(() => _board.sort = value),
          ),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                _emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            for (final question in questions) ...[
              _QuestionCard(
                question: question,
                liking: _likingId == question.id,
                repliesOpen: _openRepliesId == question.id,
                replies: _replies[question.id] ?? const [],
                repliesLoading: _loadingReplies.contains(question.id),
                replyError: _openRepliesId == question.id ? _replyError : null,
                replyController: _replyController,
                replySubmitting: _replySubmitting,
                replySendKey: _replySendKey,
                onLike: () => _toggleLike(question),
                onReply: () => _toggleReplies(question),
                onSubmitReply: () => _submitReply(question),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  String get _emptyMessage {
    switch (_board.sort) {
      case QuestionSort.answered:
        return 'No answered questions yet.';
      case QuestionSort.popular:
      case QuestionSort.recent:
        return 'No questions in this view yet.';
    }
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
    required this.liking,
    required this.repliesOpen,
    required this.replies,
    required this.repliesLoading,
    required this.replyError,
    required this.replyController,
    required this.replySubmitting,
    required this.replySendKey,
    required this.onLike,
    required this.onReply,
    required this.onSubmitReply,
  });

  final CongressQuestion question;
  final bool liking;
  final bool repliesOpen;
  final List<QuestionReply> replies;
  final bool repliesLoading;
  final String? replyError;
  final TextEditingController replyController;
  final bool replySubmitting;
  final Key replySendKey;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onSubmitReply;

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
    final highlighted = question.answered;

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
              _UpvoteControl(
                key: ValueKey('like-${question.id}'),
                likes: question.likeCount,
                liked: question.likedByMe,
                loading: liking,
                onLike: liking ? null : onLike,
              ),
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
                  question.authorName,
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
              if (question.replyCount > 0) ...[
                Text(
                  question.replyCount == 1
                      ? '1 reply'
                      : '${question.replyCount} replies',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply_rounded, size: 16),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                  foregroundColor: repliesOpen
                      ? AppColors.accentBlue
                      : AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 26),
                ),
              ),
            ],
          ),
          if (repliesOpen) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.fieldBorder),
            const SizedBox(height: 12),
            if (repliesLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (replies.isEmpty && !repliesLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'No replies yet.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else
              for (final reply in replies) ...[
                _ReplyTile(reply: reply),
                const SizedBox(height: 10),
              ],
            TextField(
              controller: replyController,
              minLines: 1,
              maxLines: 3,
              maxLength: QaBoard.replyMaxLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmitReply(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.3,
              ),
              cursorColor: AppColors.accentBlue,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Write a reply...',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF4F6FB),
                contentPadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accentBlue),
                ),
              ),
            ),
            if (replyError != null) ...[
              const SizedBox(height: 8),
              Text(
                replyError!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: replySendKey,
                onPressed: replySubmitting ? null : onSubmitReply,
                child: replySubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send reply'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply});

  final QuestionReply reply;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reply.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (reply.createdAt != null)
                  Text(
                    _formatTimestamp(reply.createdAt!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reply.body,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} · $hour:$minute';
}

class _UpvoteControl extends StatelessWidget {
  const _UpvoteControl({
    super.key,
    required this.likes,
    required this.liked,
    required this.loading,
    required this.onLike,
  });

  final int likes;
  final bool liked;
  final bool loading;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: liked ? 'Remove like' : 'Like',
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
              border: Border.all(
                color: liked ? AppColors.accentBlue : AppColors.fieldBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  liked
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_up_outlined,
                  color: liked ? AppColors.accentBlue : AppColors.textSecondary,
                ),
                if (loading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  )
                else
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
