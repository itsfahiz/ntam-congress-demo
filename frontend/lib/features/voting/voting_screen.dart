import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/gradient_button.dart';
import 'data/polls_repository.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final Map<String, String> _pending = {};
  var _polls = <LivePoll>[];
  var _index = 0;
  String? _validation;
  String? _loadError;
  var _loading = true;
  var _submitting = false;

  PollsRepository get _repository => PollsScope.of(context);

  LivePoll? get _poll {
    if (_polls.isEmpty) return null;
    final index = _index.clamp(0, _polls.length - 1);
    return _polls[index];
  }

  bool get _voted => _poll?.hasVoted ?? false;

  String? get _selectedOptionId {
    final poll = _poll;
    if (poll == null) return null;
    return poll.myOptionId ?? _pending[poll.id];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool showNotice = false}) async {
    setState(() {
      _loading = true;
      _loadError = null;
      _validation = null;
    });
    try {
      final polls = await _repository.list();
      if (!mounted) return;
      setState(() {
        _polls = polls;
        if (_index >= polls.length) _index = 0;
        _loading = false;
        for (final poll in polls) {
          if (poll.hasVoted) _pending.remove(poll.id);
        }
      });
      if (showNotice) _showNotice('Results updated');
    } on PollsException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load the live poll. Try again.';
        _loading = false;
      });
    }
  }

  void _showNotice(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 108),
        content: Text(message),
      ),
    );
  }

  void _selectPoll(int index) {
    if (index < 0 || index >= _polls.length || index == _index) return;
    setState(() {
      _index = index;
      _validation = null;
    });
  }

  void _previousPoll() => _selectPoll(_index - 1);

  void _nextPoll() => _selectPoll(_index + 1);

  void _advanceAfterVote() {
    if (_polls.length < 2) return;
    setState(() {
      _validation = null;
      _index = (_index + 1) % _polls.length;
    });
  }

  Future<void> _submit() async {
    final poll = _poll;
    final optionId = poll == null ? null : _pending[poll.id];
    if (poll == null) return;
    if (poll.hasVoted) {
      setState(() => _validation = 'You already voted in this poll.');
      return;
    }
    if (optionId == null) {
      setState(() => _validation = 'Choose an answer to vote.');
      return;
    }

    setState(() {
      _submitting = true;
      _validation = null;
    });
    try {
      final updated = await _repository.vote(
        pollId: poll.id,
        optionId: optionId,
      );
      if (!mounted) return;
      setState(() {
        _polls = [
          for (final item in _polls)
            if (item.id == updated.id) updated else item,
        ];
        _pending.remove(poll.id);
        _submitting = false;
      });
      _showNotice('Vote submitted');
    } on PollsException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _validation = error.message;
      });
      if (error.alreadyVoted) {
        await _load();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _validation = 'Could not submit your vote. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = _poll;
    final voted = _voted;
    final atFirst = _index <= 0;
    final atLast = _polls.isEmpty || _index >= _polls.length - 1;

    return CongressFeatureScaffold(
      title: 'Live Voting',
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
        icon: Icons.restart_alt_rounded,
        tooltip: 'Refresh results',
        outlined: true,
        foreground: AppColors.gold,
        onPressed: () {
          if (_loading) return;
          _load(showNotice: true);
        },
      ),
      hero: const CongressHeroBanner(
        icon: Icons.bar_chart_rounded,
        title: 'Audience Interaction',
        subtitle: 'Swipe polls, choose answers, and submit your vote',
        gradient: AppColors.goldBadge,
        padding: EdgeInsets.fromLTRB(18, 20, 18, 20),
        titleSize: 20,
        titleWeight: FontWeight.w900,
        badgeSize: 56,
        titleSpacing: 8,
        contentSpacing: 16,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _PollIndicators(
            count: _polls.isEmpty ? 1 : _polls.length,
            index: _polls.isEmpty ? 0 : _index,
            onSelected: _selectPoll,
          ),
          Expanded(child: _body(poll, voted)),
          if (_validation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _validation!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(
              children: [
                _SquareNavButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous poll',
                  onPressed: _polls.length > 1 && !atFirst
                      ? _previousPoll
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    key: ValueKey(voted ? 'next-poll' : 'submit-vote'),
                    label: voted ? 'Next Poll' : 'Submit Vote',
                    showArrow: false,
                    loading: _submitting,
                    gradient: voted
                        ? AppColors.createAccountButton
                        : AppColors.primaryButton,
                    onPressed: poll == null || _submitting
                        ? null
                        : voted
                        ? _advanceAfterVote
                        : _submit,
                  ),
                ),
                const SizedBox(width: 12),
                _SquareNavButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: atLast ? 'Last poll' : 'Next poll',
                  onPressed: _polls.length > 1 && !atLast ? _nextPoll : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(LivePoll? poll, bool voted) {
    if (poll == null) {
      if (_loading) return const _PollLoadingCard();
      return _PollErrorCard(
        message: _loadError ?? 'No active poll.',
        onRetry: _load,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (voted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ceremonyWash,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusPill,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.gold,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'VOTED',
                              style: TextStyle(
                                color: AppColors.categoryInk,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.talkWash,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusPill,
                          ),
                        ),
                        child: const Text(
                          'OPEN',
                          style: TextStyle(
                            color: AppColors.navyChip,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        poll.topicLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_index + 1} of ${_polls.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  poll.question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (voted) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Live results',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                for (final option in poll.options) ...[
                  _PollOptionTile(
                    key: ValueKey('poll-option-${option.id}'),
                    option: option,
                    selected: _selectedOptionId == option.id,
                    voted: voted,
                    onTap: () => setState(() {
                      _validation = null;
                      if (!poll.hasVoted) _pending[poll.id] = option.id;
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _pollCardDecoration() {
  return BoxDecoration(
    color: AppColors.fieldFill,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: AppColors.navy.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

class _PollLoadingCard extends StatefulWidget {
  const _PollLoadingCard();

  @override
  State<_PollLoadingCard> createState() => _PollLoadingCardState();
}

class _PollLoadingCardState extends State<_PollLoadingCard> {
  var _slowStart = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _slowStart = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        DecoratedBox(
          decoration: _pollCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _SkeletonPill(),
                    SizedBox(width: 10),
                    Expanded(child: _SkeletonBar(height: 12)),
                    SizedBox(width: 12),
                    _SkeletonBar(width: 40, height: 12),
                  ],
                ),
                const SizedBox(height: 16),
                const _SkeletonBar(height: 22),
                const SizedBox(height: 8),
                const _SkeletonBar(width: 210, height: 22),
                const SizedBox(height: 16),
                const Row(
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
                    Expanded(
                      child: Text(
                        'Loading live polls…',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_slowStart) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'This can take a moment on first load.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const _OptionSkeleton(),
                const SizedBox(height: 10),
                const _OptionSkeleton(),
                const SizedBox(height: 10),
                const _OptionSkeleton(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PollErrorCard extends StatelessWidget {
  const _PollErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        DecoratedBox(
          decoration: _pollCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.talkWash,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.accentBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Could not load live polls',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  key: const ValueKey('retry-polls'),
                  label: 'Retry',
                  showArrow: false,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonPill extends StatelessWidget {
  const _SkeletonPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.talkWash,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.searchFill,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _OptionSkeleton extends StatelessWidget {
  const _OptionSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Row(
          children: [
            Icon(Icons.circle_outlined, color: AppColors.fieldBorder),
            SizedBox(width: 10),
            Expanded(child: _SkeletonBar(height: 14)),
          ],
        ),
      ),
    );
  }
}

class _PollIndicators extends StatelessWidget {
  const _PollIndicators({
    required this.count,
    required this.index,
    required this.onSelected,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: i == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index
                    ? AppColors.accentBlue
                    : AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PollOptionTile extends StatelessWidget {
  const _PollOptionTile({
    super.key,
    required this.option,
    required this.selected,
    required this.voted,
    required this.onTap,
  });

  final LivePollOption option;
  final bool selected;
  final bool voted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = voted && selected
        ? AppColors.talkWash
        : const Color(0xFFF4F6FB);
    final voteLabel = option.voteCount == 1
        ? '1 vote'
        : '${option.voteCount} votes';

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: voted ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accentBlue : AppColors.fieldBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? AppColors.accentBlue
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (voted)
                    Text(
                      '${option.percent}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              if (voted) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: option.percent / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.searchFill,
                    color: selected ? AppColors.gold : AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    voteLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareNavButton extends StatelessWidget {
  const _SquareNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.fieldFill,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
