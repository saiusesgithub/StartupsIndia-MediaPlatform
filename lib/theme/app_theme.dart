import 'package:flutter/material.dart';
import 'style_guide.dart';

class AppTheme {
  // Backward compatibility alias variables (using the central generic tokens from style_guide.dart)
  static const Color background = AppColors.grayscaleWhite;
  static const Color primary = AppColors.primaryDefault;
  static const Color titleActive = AppColors.grayscaleTitleActive;
  static const Color bodyText = AppColors.grayscaleBodyText;
  static const Color secondaryButton = AppColors.grayscaleSecondaryButton;
  static const Color buttonTextSecondary = AppColors.grayscaleButtonText;
  static const Color white = AppColors.grayscaleWhite;

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.grayscaleWhite,
      primaryColor: AppColors.primaryDefault,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDefault,
        background: AppColors.grayscaleWhite,
      ),
      textTheme: TextTheme(
        displayMedium: AppTypography.displayMediumBold.copyWith(
          color: AppColors.grayscaleTitleActive,
        ),
        bodyLarge: AppTypography.textMedium.copyWith(
          color: AppColors.grayscaleBodyText,
        ),
        bodyMedium: AppTypography.textSmall.copyWith(
          color: AppColors.grayscaleButtonText,
        ),
        bodySmall: AppTypography.textSmall.copyWith(
          fontSize: 13,
          color: AppColors.grayscaleButtonText,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.grayscaleWhite,
        ),
      ),
    );
  }
}
