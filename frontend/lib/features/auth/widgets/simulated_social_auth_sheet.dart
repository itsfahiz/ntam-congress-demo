import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/light_sheet.dart';

/// Google/Apple are not configured. This sheet does not sign anyone in.
Future<void> showSimulatedSocialAuthSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String dismissLabel,
  required ValueChanged<String> onError,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    showDragHandle: true,
    builder: (context) {
      return LightSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(dismissLabel),
              ),
            ],
          ),
        ),
      );
    },
  );
}
