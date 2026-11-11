import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class FilterChipOption<T> {
  const FilterChipOption({required this.value, required this.label});

  final T? value;
  final String label;
}

enum ChipAccent { navy, gold }

class CongressFilterChips<T> extends StatelessWidget {
  const CongressFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.accent = ChipAccent.navy,
    this.selectedFill,
    this.unselectedForeground,
    this.unselectedWeight,
    this.unselectedBorder,
  });

  final List<FilterChipOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final ChipAccent accent;
  final Color? selectedFill;
  final Color? unselectedForeground;
  final FontWeight? unselectedWeight;
  final Color? unselectedBorder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _ChipButton(
              label: options[i].label,
              selected: selected == options[i].value,
              accent: accent,
              selectedFill: selectedFill,
              unselectedForeground: unselectedForeground,
              unselectedWeight: unselectedWeight,
              unselectedBorder: unselectedBorder,
              onTap: () => onSelected(options[i].value),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.accent,
    this.selectedFill,
    this.unselectedForeground,
    this.unselectedWeight,
    this.unselectedBorder,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ChipAccent accent;
  final Color? selectedFill;
  final Color? unselectedForeground;
  final FontWeight? unselectedWeight;
  final Color? unselectedBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        selectedFill ??
        (accent == ChipAccent.gold ? AppColors.gold : AppColors.navyChip);
    final selectedTextColor = accent == ChipAccent.gold && selectedFill == null
        ? AppColors.navyDeep
        : Colors.white;
    final idleColor = unselectedForeground ?? AppColors.textPrimary;

    return Material(
      color: selected ? selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : (unselectedBorder ?? AppColors.fieldBorder),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? selectedTextColor : idleColor,
              fontWeight: selected
                  ? FontWeight.w700
                  : (unselectedWeight ?? FontWeight.w700),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
