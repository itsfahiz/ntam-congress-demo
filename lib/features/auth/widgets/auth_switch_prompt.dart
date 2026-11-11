import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onAction,
    this.showArrow = false,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
