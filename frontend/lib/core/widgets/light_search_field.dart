import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class LightSearchField extends StatelessWidget {
  const LightSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.fillColor = AppColors.searchFill,
    this.borderColor,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Color fillColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.accentBlue,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          borderSide: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          borderSide: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          borderSide: BorderSide(
            color: borderColor == null
                ? AppColors.accentBlue
                : AppColors.iconBlue,
          ),
        ),
      ),
    );
  }
}
