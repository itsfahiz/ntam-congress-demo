import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/auth_card.dart';
import '../../../../core/widgets/congress_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/social_auth_row.dart';
import '../../auth_validators.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.autovalidateMode,
    required this.obscurePassword,
    required this.loading,
    required this.errorMessage,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onGoogle,
    required this.onApple,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final AutovalidateMode autovalidateMode;
  final bool obscurePassword;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onToggleObscure;
  final VoidCallback onSignIn;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Form(
        key: formKey,
        autovalidateMode: autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to continue your congress experience',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            CongressTextField(
              controller: emailController,
              enabled: !loading,
              hintText: 'Enter your email',
              prefixIcon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 12),
            CongressTextField(
              controller: passwordController,
              enabled: !loading,
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => onSignIn(),
              validator: AuthValidators.password,
              suffix: IconButton(
                onPressed: loading ? null : onToggleObscure,
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            GradientButton(
              label: 'Sign In',
              loading: loading,
              onPressed: loading ? null : onSignIn,
            ),
            const SizedBox(height: 18),
            SocialAuthRow(
              dividerLabel: 'OR CONTINUE WITH',
              onGoogle: loading ? null : onGoogle,
              onApple: loading ? null : onApple,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: loading ? null : onForgotPassword,
                icon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.iconBlue,
                ),
                label: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.iconBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
