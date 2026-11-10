import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Light-surface wrapper so bottom sheets stay readable on the dark app theme.
class LightSheet extends StatelessWidget {
  const LightSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentBlue,
          onPrimary: Colors.white,
          surface: AppColors.card,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          titleMedium: TextStyle(color: AppColors.textPrimary),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.iconBlue,
          textColor: AppColors.textPrimary,
        ),
      ),
      child: child,
    );
  }
}
