import 'package:flutter/material.dart';

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

  void _submit() {
    final result = _board.submit();
    switch (result) {
      case VoteCastResult.missingSelection:
        setState(() => _validation = 'Choose an answer to submit a demo vote.');
      case VoteCastResult.alreadyVoted:
        setState(
          () => _validation =
              'You already voted in this poll. Reset demo votes to try again.',
        );
      case VoteCastResult.recorded:
        setState(() => _validation = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vote saved on this device. Results are simulated, not live counts.',
            ),
          ),
        );
    }
  }

  void _reset() {
    setState(() {
      _board.reset();
      _validation = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo votes were cleared on this screen.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poll = _board.current;
    final voted = _board.hasVotedCurrent;

    return CongressFeatureScaffold(
      title: 'Live Voting',
      trailing: CongressGoldHeaderButton(
        icon: Icons.restart_alt_rounded,
        tooltip: 'Reset demo votes',
        onPressed: _reset,
      ),
      hero: const CongressHeroBanner(
        icon: Icons.bar_chart_rounded,
        title: 'Audience Interaction',
        subtitle: 'Swipe polls, choose answers, and submit your vote',
        gradient: AppColors.goldBadge,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                      '${_board.index + 1} / ${_board.polls.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  poll.question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  voted
                      ? 'Simulated sample · ${_board.simulatedTotal(poll)} local votes'
                      : 'Choose an answer. Counts stay on this device and are not live.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
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
                const Text(
                  'Votes reset if you leave this screen. Results are simulated, not live attendee counts.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
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
                _RoundNavButton(
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
                    onPressed: voted
                        ? () => setState(() {
                            _validation = null;
                            _board.nextPoll();
                          })
                        : _submit,
                  ),
                ),
                const SizedBox(width: 12),
                _RoundNavButton(
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
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: voted ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
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
                    '$count simulated votes',
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

class _RoundNavButton extends StatelessWidget {
  const _RoundNavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.searchFill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
