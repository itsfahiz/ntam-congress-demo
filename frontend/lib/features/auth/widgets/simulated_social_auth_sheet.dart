import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/light_sheet.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../state/auth_controller.dart';

/// Explains that Google/Apple are not connected, then optionally signs in
/// the seeded local attendee.
Future<void> showSimulatedSocialAuthSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String dismissLabel,
  required ValueChanged<String> onError,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
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
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue as demo attendee'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(dismissLabel),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  FocusScope.of(context).unfocus();
  try {
    await AuthScope.of(context).signIn(
      email: MockAuthRepository.demoAttendee.email,
      password: MockAuthRepository.demoPassword,
    );
  } on AuthException catch (error) {
    onError(error.message);
  }
}
