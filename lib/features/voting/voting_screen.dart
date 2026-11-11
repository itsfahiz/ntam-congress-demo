import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/gradient_button.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import 'voting_board.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  late final VotingBoard _board;
  String? _validation;

  @override
  void initState() {
    super.initState();
    _board = VotingBoard(CongressCatalog.polls);
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

  void _submit() {
    final result = _board.submit();
    switch (result) {
      case VoteCastResult.missingSelection:
        setState(() => _validation = 'Choose an answer to vote.');
      case VoteCastResult.alreadyVoted:
        setState(() => _validation = 'You already voted in this poll.');
      case VoteCastResult.recorded:
        setState(() => _validation = null);
        _showNotice('Vote submitted');
    }
  }

  void _reset() {
    setState(() {
      _board.reset();
      _validation = null;
    });
    _showNotice('Votes cleared');
  }

  @override
  Widget build(BuildContext context) {
    final poll = _board.current;
    final voted = _board.hasVotedCurrent;

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
        tooltip: 'Reset demo votes',
        outlined: true,
        foreground: AppColors.gold,
        onPressed: _reset,
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
            count: _board.polls.length,
            index: _board.index,
            onSelected: (index) => setState(() {
              _validation = null;
              _board.index = index;
            }),
          ),
          Expanded(
            child: ListView(
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
                            'Simulated results',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        for (final option in poll.options) ...[
                          _PollOptionTile(
                            option: option,
                            selected: _board.selectedOptionId == option.id,
                            voted: voted,
                            percent: _board.simulatedPercent(poll, option),
                            count: _board.simulatedCount(poll, option),
                            onTap: () => setState(() {
                              _validation = null;
                              _board.select(option.id);
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  onPressed: _board.hasMultiplePolls
                      ? () => setState(() {
                          _validation = null;
                          _board.previousPoll();
                        })
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    key: ValueKey(voted ? 'next-poll' : 'submit-vote'),
                    label: voted ? 'Next Poll' : 'Submit Vote',
                    showArrow: false,
                    gradient: voted
                        ? AppColors.createAccountButton
                        : AppColors.primaryButton,
                    onPressed: voted
                        ? () => setState(() {
                            _validation = null;
                            _board.nextPoll();
                          })
                        : _submit,
                  ),
                ),
                const SizedBox(width: 12),
                _SquareNavButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next poll',
                  onPressed: _board.hasMultiplePolls
                      ? () => setState(() {
                          _validation = null;
                          _board.nextPoll();
                        })
                      : null,
                ),
              ],
            ),
          ),
        ],
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
    required this.option,
    required this.selected,
    required this.voted,
    required this.percent,
    required this.count,
    required this.onTap,
  });

  final PollOption option;
  final bool selected;
  final bool voted;
  final int percent;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = voted && selected
        ? AppColors.talkWash
        : const Color(0xFFF4F6FB);

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
                      '$percent%',
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
                    value: percent / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.searchFill,
                    color: selected ? AppColors.gold : AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$count votes',
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
