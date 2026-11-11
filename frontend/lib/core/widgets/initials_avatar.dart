import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 64,
    this.featured = false,
    this.fillColor = Colors.white,
    this.initialsColor = AppColors.textPrimary,
  });

  final String initials;
  final double size;
  final bool featured;
  final Color fillColor;
  final Color initialsColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: featured
              ? const [AppColors.gold, AppColors.gradientEnd]
              : const [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: initialsColor,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.28,
            ),
          ),
        ),
      ),
    );
  }
}
