import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'gradient_icon_badge.dart';

class CongressHeroBanner extends StatelessWidget {
  const CongressHeroBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradient = AppColors.primaryButton,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.titleSize = 18,
    this.titleWeight = FontWeight.w800,
    this.badgeSize = 52,
    this.titleSpacing = 4,
    this.contentSpacing = 14,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final EdgeInsetsGeometry padding;
  final double titleSize;
  final FontWeight titleWeight;
  final double badgeSize;
  final double titleSpacing;
  final double contentSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          GradientIconBadge(
            icon: icon,
            size: badgeSize,
            iconSize: badgeSize * 0.5,
            gradient: gradient,
          ),
          SizedBox(width: contentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: titleWeight,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: titleSpacing),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
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
