import 'package:flutter/material.dart';

/// Visual tokens sampled from the Nestlé Medical Congress reference screens.
abstract final class AppColors {
  static const navyDeep = Color(0xFF04122F);
  static const navy = Color(0xFF071B48);
  static const navyGlow = Color(0xFF1A4C9C);

  static const gold = Color(0xFFF0C14B);

  static const accentBlue = Color(0xFF2F6BFF);
  static const gradientStart = Color(0xFF1A4DFF);
  static const gradientEnd = Color(0xFF4EC8FF);
  static const googleBlue = Color(0xFF4285F4);

  static const card = Color(0xFFF6F7FC);
  static const fieldFill = Color(0xFFFFFFFF);
  static const fieldBorder = Color(0xFFE6EAF3);
  static const fieldIconWash = Color(0xFFEDF2FB);
  static const checkboxBorder = Color(0xFFB8BFC9);
  static const searchFill = Color(0xFFF3F5FB);
  static const textPrimary = Color(0xFF14213D);
  static const loginTitle = Color(0xFF1A2744);
  static const loginSubtitle = Color(0xFF5C6578);
  static const textSecondary = Color(0xFF7B8499);
  static const mutedLabel = Color(0xFF6A7386);
  static const iconBlue = Color(0xFF2F6CFF);

  static const error = Color(0xFFD64545);
  static const notice = Color(0xFFE5484D);

  static const navyChip = Color(0xFF1C3F9A);
  static const categoryWash = Color(0xFFFFF4DE);
  static const categoryInk = Color(0xFFB8860B);
  static const ceremonyWash = Color(0xFFFFF3D6);
  static const talkWash = Color(0xFFE7F3FF);
  static const nutritionWash = Color(0xFFE6F8F0);
  static const researchWash = Color(0xFFEEF0FF);
  static const nutritionAccent = Color(0xFF1DBF73);
  static const researchAccent = Color(0xFF6B7CFF);
  static const mapWash = Color(0xFFE7F2FF);
  static const mapDeep = Color(0xFFD5E8FF);

  static const LinearGradient primaryButton = LinearGradient(
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient signInButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1146EB), Color(0xFF5CCFFF)],
  );

  static const LinearGradient createAccountButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF5CCFFF), Color(0xFF1146EB)],
  );

  static const LinearGradient goldBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD36A), Color(0xFFF5A623)],
  );

  static const LinearGradient nightSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A2460), Color(0xFF071B48), Color(0xFF030D28)],
  );
}

abstract final class AppSizes {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;

  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;
  static const radiusXl = 28.0;
  static const radiusPill = 999.0;

  static const maxContentWidth = 440.0;
}
