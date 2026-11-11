import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class LoginFeaturePills extends StatelessWidget {
  const LoginFeaturePills({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _FeatureSegment(
              icon: Icons.groups_outlined,
              label: 'Global Experts',
              color: AppColors.gradientEnd,
            ),
          ),
          _SegmentDivider(),
          Expanded(
            child: _FeatureSegment(
              icon: Icons.calendar_today_outlined,
              label: 'Knowledge Sessions',
              color: AppColors.gradientEnd,
            ),
          ),
          _SegmentDivider(),
          Expanded(
            child: _FeatureSegment(
              icon: Icons.star_border_rounded,
              label: 'Networking Opportunities',
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentDivider extends StatelessWidget {
  const _SegmentDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _FeatureSegment extends StatelessWidget {
  const _FeatureSegment({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
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
