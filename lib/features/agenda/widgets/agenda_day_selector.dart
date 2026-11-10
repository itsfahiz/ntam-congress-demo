import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../congress/data/congress_catalog.dart';
import '../../congress/domain/congress_models.dart';

class AgendaDaySelector extends StatelessWidget {
  const AgendaDaySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CongressDay selected;
  final ValueChanged<CongressDay> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < CongressCatalog.days.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _DayButton(
              key: ValueKey(CongressCatalog.days[i].shortLabel),
              info: CongressCatalog.days[i],
              selected: CongressCatalog.days[i].day == selected,
              onTap: () => onSelected(CongressCatalog.days[i].day),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    super.key,
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final CongressDayInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                info.shortLabel,
                style: TextStyle(
                  color: selected ? AppColors.navyDeep : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                info.dateShort,
                style: TextStyle(
                  color: selected
                      ? AppColors.navyDeep.withValues(alpha: 0.72)
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
