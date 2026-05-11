import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'style_guide.dart';

class AppTheme {
  // Legacy alias kept for backward compatibility
  static const Color background      = AppColors.grayscaleWhite;
  static const Color primary         = AppColors.primaryDefault;
  static const Color titleActive     = AppColors.grayscaleTitleActive;
  static const Color bodyText        = AppColors.grayscaleBodyText;
  static const Color secondaryButton = AppColors.grayscaleSecondaryButton;
  static const Color buttonTextSecondary = AppColors.grayscaleButtonText;
  static const Color white           = AppColors.grayscaleWhite;

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.grayscaleWhite,
      primaryColor: AppColors.primaryDefault,
      splashColor: AppColors.primaryDefault.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,

      colorScheme: const ColorScheme.light(
        primary:        AppColors.primaryDefault,
        onPrimary:      AppColors.grayscaleWhite,
        secondary:      AppColors.primaryLight,
        onSecondary:    AppColors.grayscaleWhite,
        error:          AppColors.errorDefault,
        surface:        AppColors.grayscaleWhite,
        onSurface:      AppColors.grayscaleTitleActive,
        surfaceContainerHighest: AppColors.grayscaleInputBackground,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.grayscaleWhite,
        foregroundColor: AppColors.grayscaleTitleActive,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDefault,
          foregroundColor: AppColors.grayscaleWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.linkMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDefault,
          side: const BorderSide(color: AppColors.primaryDefault),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── Input fields: clean baseline — no global fill or border.
      // Each widget (AppTextField, search bars, etc.) applies its own decoration.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: AppTypography.textSmall.copyWith(
          color: AppColors.grayscaleButtonText,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.grayscaleLine,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.grayscaleWhite,
        selectedItemColor: AppColors.primaryDefault,
        unselectedItemColor: AppColors.grayscaleButtonText,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.textSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.textSmall.copyWith(fontSize: 10),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryDefault;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.grayscaleWhite),
        side: const BorderSide(color: AppColors.grayscaleLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.grayscaleWhite;
          return AppColors.grayscaleButtonText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryDefault;
          return AppColors.grayscaleSecondaryButton;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryDefault,
      ),

      chipTheme: ChipThemeData(
        selectedColor: AppColors.primaryDefault,
        backgroundColor: AppColors.grayscaleSecondaryButton,
        labelStyle: AppTypography.textSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      textTheme: TextTheme(
        displayMedium: AppTypography.displayMediumBold.copyWith(color: AppColors.grayscaleTitleActive),
        bodyLarge:     AppTypography.textMedium.copyWith(color: AppColors.grayscaleBodyText),
        bodyMedium:    AppTypography.textSmall.copyWith(color: AppColors.grayscaleButtonText),
        bodySmall:     AppTypography.textSmall.copyWith(fontSize: 13, color: AppColors.grayscaleButtonText),
        labelLarge:    AppTypography.labelLarge.copyWith(color: AppColors.grayscaleWhite),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryDefault,
      splashColor: AppColors.primaryDefault.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,

      colorScheme: const ColorScheme.dark(
        primary:        AppColors.primaryDefault,
        onPrimary:      AppColors.grayscaleWhite,
        secondary:      AppColors.primaryLight,
        onSecondary:    AppColors.grayscaleWhite,
        error:          AppColors.errorDefault,
        surface:        AppColors.darkSurface,
        onSurface:      AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkInputBackground,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDefault,
          foregroundColor: AppColors.grayscaleWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.linkMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDefault,
          side: const BorderSide(color: AppColors.primaryDefault),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── Input fields: clean baseline — no global fill or border.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: AppTypography.textSmall.copyWith(
          color: AppColors.darkTextSecondary,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryDefault,
        unselectedItemColor: AppColors.darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.textSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.textSmall.copyWith(fontSize: 10),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryDefault;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.grayscaleWhite),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.grayscaleWhite;
          return AppColors.darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryDefault;
          return AppColors.darkBorder;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryDefault,
      ),

      chipTheme: ChipThemeData(
        selectedColor: AppColors.primaryDefault,
        backgroundColor: AppColors.darkSurface,
        labelStyle: AppTypography.textSmall.copyWith(color: AppColors.darkTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      textTheme: TextTheme(
        displayMedium: AppTypography.displayMediumBold.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge:     AppTypography.textMedium.copyWith(color: AppColors.darkTextSecondary),
        bodyMedium:    AppTypography.textSmall.copyWith(color: AppColors.darkTextSecondary),
        bodySmall:     AppTypography.textSmall.copyWith(fontSize: 13, color: AppColors.darkTextSecondary),
        labelLarge:    AppTypography.labelLarge.copyWith(color: AppColors.grayscaleWhite),
      ),
    );
  }
}
