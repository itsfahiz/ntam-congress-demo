import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({
    super.key,
    required this.dividerLabel,
    required this.onGoogle,
    required this.onApple,
    this.simpleGoogleMark = false,
  });

  final String dividerLabel;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool simpleGoogleMark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.fieldBorder.withValues(alpha: 0.9),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                dividerLabel,
                style: const TextStyle(
                  color: AppColors.mutedLabel,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.fieldBorder.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                onPressed: onGoogle,
                child: simpleGoogleMark
                    ? const _SimpleGoogleMark()
                    : const _GoogleMark(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                onPressed: onApple,
                child: const Icon(Icons.apple, color: Colors.black, size: 26),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.fieldBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SimpleGoogleMark extends StatelessWidget {
  const _SimpleGoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      semanticsLabel: 'Google',
      style: TextStyle(
        color: AppColors.googleBlue,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1,
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/google_g.png',
      width: 24,
      height: 24,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Google',
    );
  }
}
