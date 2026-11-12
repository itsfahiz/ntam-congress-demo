import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_text_field.dart';
import '../agenda/widgets/session_detail_sheet.dart';
import '../auth/state/auth_controller.dart';
import '../speakers/widgets/speaker_detail_sheet.dart';
import 'assistant_answer_text.dart';
import 'assistant_local.dart';
import 'catalog_lookup.dart';
import 'data/assistant_models.dart';
import 'data/assistant_repository.dart';
import 'data/http_assistant_repository.dart';

const suggestedQuestions = [
  'Who is speaking at Future of Pediatric Nutrition?',
  'When is the opening ceremony?',
  'Where is the venue and what facilities are listed?',
];

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.repository});

  final AssistantRepository? repository;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  var _requestSeq = 0;
  var _sending = false;

  AssistantRepository get _repository {
    return widget.repository ?? AssistantScope.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final question = raw.trim();
    if (question.length < 2 || _sending) return;

    final id = 'm-${++_requestSeq}';
    setState(() {
      _sending = true;
      _controller.clear();
      _messages.add(
        ChatMessage(id: id, question: question, loading: true),
      );
    });
    _scrollToEnd();

    final local = localAssistantReply(
      question,
      AuthScope.maybeOf(context)?.attendee,
    );
    if (local != null) {
      if (!mounted) return;
      _replace(id, ChatMessage(id: id, question: question, reply: local));
      return;
    }

    try {
      final reply = await _repository.ask(question);
      if (!mounted) return;
      _replace(
        id,
        ChatMessage(id: id, question: question, reply: reply),
      );
    } on AssistantException catch (error) {
      if (!mounted) return;
      _replace(
        id,
        ChatMessage(id: id, question: question, error: error),
      );
    } catch (_) {
      if (!mounted) return;
      _replace(
        id,
        ChatMessage(
          id: id,
          question: question,
          error: const AssistantException(
            'The assistant is temporarily unavailable. Try again shortly.',
          ),
        ),
      );
    }
  }

  void _replace(String id, ChatMessage next) {
    setState(() {
      final index = _messages.indexWhere((item) => item.id == id);
      if (index >= 0) {
        _messages[index] = next;
      }
      _sending = _messages.any((item) => item.loading);
    });
    _scrollToEnd();
  }

  Future<void> _retry(ChatMessage message) {
    setState(() {
      _messages.removeWhere((item) => item.id == message.id);
    });
    return _submit(message.question);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSource(AssistantSource source) async {
    if (source.isSession) {
      final session = catalogSession(source.id);
      if (session == null) return;
      await showSessionDetailSheet(context, session: session);
      return;
    }
    if (source.isSpeaker) {
      final speaker = catalogSpeaker(source.id);
      if (speaker == null) return;
      await showSpeakerDetailSheet(context, speaker: speaker);
      return;
    }
    if (source.isDay && (source.id == 'day1' || source.id == 'day2')) {
      context.push(AppRoutes.agenda);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empty = _messages.isEmpty;

    return CongressFeatureScaffold(
      title: 'Congress AI',
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
      trailing: const SizedBox(width: 44, height: 44),
      body: Column(
        children: [
          Expanded(
            child: empty
                ? _EmptyState(
                    enabled: !_sending,
                    onQuestion: _submit,
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    itemCount: _messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _ThreadItem(
                        message: _messages[index],
                        onRetry: _retry,
                        onSourceTap: _openSource,
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CongressTextField(
                    controller: _controller,
                    hintText: 'Ask about the programme',
                    prefixIcon: Icons.auto_awesome_rounded,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_sending,
                    onSubmitted: _submit,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _SendButton(
                    loading: _sending,
                    onPressed: _sending
                        ? null
                        : () => _submit(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentBlue,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.enabled, required this.onQuestion});

  final bool enabled;
  final ValueChanged<String> onQuestion;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const Text(
          'Ask about this congress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Answers come from the on-device programme catalog via the NTAM API. No medical advice.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        for (final question in suggestedQuestions) ...[
          _SuggestionTile(
            question: question,
            onTap: enabled ? () => onQuestion(question) : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.question, required this.onTap});

  final String question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.iconBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadItem extends StatelessWidget {
  const _ThreadItem({
    required this.message,
    required this.onRetry,
    required this.onSourceTap,
  });

  final ChatMessage message;
  final ValueChanged<ChatMessage> onRetry;
  final ValueChanged<AssistantSource> onSourceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Text(
                  message.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (message.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.accentBlue,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Checking the congress catalog…',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else if (message.error != null)
          _ErrorCard(
            error: message.error!,
            onRetry: () => onRetry(message),
          )
        else if (message.reply != null)
          _AnswerCard(
            reply: message.reply!,
            onSourceTap: onSourceTap,
          ),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.reply, required this.onSourceTap});

  final AssistantReply reply;
  final ValueChanged<AssistantSource> onSourceTap;

  @override
  Widget build(BuildContext context) {
    final sources = reply.sources.where(canOpenSource).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AssistantAnswerText(
              reply.answer,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (reply.actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in reply.actions)
                    ActionChip(
                      onPressed: () => context.push(action.route),
                      backgroundColor: AppColors.fieldIconWash,
                      side: const BorderSide(color: AppColors.fieldBorder),
                      label: Text(
                        action.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Sources',
                style: TextStyle(
                  color: AppColors.mutedLabel,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final source in sources)
                    ActionChip(
                      onPressed: () => onSourceTap(source),
                      backgroundColor: AppColors.fieldIconWash,
                      side: const BorderSide(color: AppColors.fieldBorder),
                      label: Text(
                        sourceLabel(source),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final AssistantException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
