import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    this.gradient = AppColors.primaryButton,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
