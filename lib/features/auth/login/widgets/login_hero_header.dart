import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class LoginHeroHeader extends StatelessWidget {
  const LoginHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
          ),
          child: const Text(
            'NESTLÉ MEDICAL CONGRESS',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'NESTLÉ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: 0.6,
          ),
        ),
        const Text(
          'CONGRESS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 52,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'The Next Era of\nNutrition & Health',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
