import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class LoginFeaturePills extends StatelessWidget {
  const LoginFeaturePills({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FeaturePill(
            icon: Icons.groups_outlined,
            label: 'Global Experts',
            color: AppColors.gradientEnd,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _FeaturePill(
            icon: Icons.calendar_today_outlined,
            label: 'Knowledge Sessions',
            color: AppColors.gradientEnd,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _FeaturePill(
            icon: Icons.star_border_rounded,
            label: 'Networking Opportunities',
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
