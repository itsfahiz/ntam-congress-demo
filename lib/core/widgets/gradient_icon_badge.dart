import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryButton,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
