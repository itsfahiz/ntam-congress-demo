import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/auth_card.dart';
import '../../../core/widgets/gradient_button.dart';

class RegisterSuccessCard extends StatelessWidget {
  const RegisterSuccessCard({
    super.key,
    required this.email,
    required this.onContinue,
  });

  final String email;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldBadge,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Account Created!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.loginTitle,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You're one step away from joining the Nestlé Congress.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.loginSubtitle,
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "We've sent a confirmation link to your email. Verify your email before signing in.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.fieldIconWash,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.iconBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          GradientButton(
            label: 'Continue to Sign In',
            icon: Icons.login_rounded,
            gradient: AppColors.signInButton,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
