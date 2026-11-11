import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.showArrow = true,
    this.gradient = AppColors.primaryButton,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool showArrow;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? gradient
            : LinearGradient(
                begin: gradient.begin,
                end: gradient.end,
                colors: [
                  for (final color in gradient.colors)
                    color.withValues(alpha: 0.45),
                ],
              ),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
