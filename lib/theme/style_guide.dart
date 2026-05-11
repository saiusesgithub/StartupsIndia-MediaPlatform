import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The central source of truth for all foundational design tokens.
/// Brand colors are derived from the StartupsIndia visual identity:
/// Primary red (#E8341C), dark surfaces, and a clean neutral palette.
class AppColors {
  // ── Brand & Primary ────────────────────────────────────────────────────────
  /// StartupsIndia signature coral-red — used for all primary actions,
  /// active states, links, and the bottom nav indicator.
  static const Color primaryDefault   = Color(0xFFE8341C);
  static const Color primaryLight     = Color(0xFFFF5A42); // lighter tint for hover/ripple
  static const Color primaryDark      = Color(0xFFBF2510); // pressed state
  static const Color primarySurface   = Color(0xFFFFF0EE); // tinted bg in light mode

  // ── Grayscale Palette — Light Mode ────────────────────────────────────────
  static const Color grayscaleWhite          = Color(0xFFFFFFFF);
  static const Color grayscaleTitleActive    = Color(0xFF0D0D0D);
  static const Color grayscaleBodyText       = Color(0xFF4E4B66);
  static const Color grayscaleButtonText     = Color(0xFF667080);
  static const Color grayscaleSecondaryButton = Color(0xFFEEF1F4);
  static const Color grayscaleLine           = Color(0xFFE4E4E4);
  static const Color grayscaleInputBackground = Color(0xFFFAFAFA);

  // ── Dark Mode Surfaces ────────────────────────────────────────────────────
  /// Pure app background in dark mode — matches StartupsIndia hero section
  static const Color darkBackground     = Color(0xFF0D0D0D);
  /// Elevated cards / nav bar surface
  static const Color darkSurface        = Color(0xFF1C1C1E);
  /// Subtle dividers and borders in dark mode
  static const Color darkBorder         = Color(0xFF2C2C2E);
  /// Primary text in dark mode
  static const Color darkTextPrimary    = Color(0xFFF5F5F5);
  /// Secondary / body text in dark mode
  static const Color darkTextSecondary  = Color(0xFF98989F);
  /// Input / search bar background in dark mode
  static const Color darkInputBackground = Color(0xFF242426);

  // ── Status & Feedback ─────────────────────────────────────────────────────
  static const Color errorDefault = Color(0xFFED2E7E);
  static const Color successDefault = Color(0xFF00BA88);
  static const Color warningDefault = Color(0xFFF4B740);
  static const Color errorLight = Color(0xFFFFF3F8);
  static const Color errorDark  = Color(0xFFC30052);

  /// Legacy alias kept for backward compatibility (was blue; now same as primary)
  static const Color linkBlue = primaryDefault;
}

class AppTypography {
  static TextStyle displayLargeBold = GoogleFonts.poppins(
    fontWeight: FontWeight.w700,
    fontSize: 48,
    height: 1.5,
    letterSpacing: 0.25 * 48 / 100,
  );

  static TextStyle textLarge = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    height: 1.5,
    letterSpacing: 0.60 * 20 / 100,
  );

  static TextStyle displayMediumBold = GoogleFonts.poppins(
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.5,
    letterSpacing: 0.12,
  );

  static TextStyle displaySmallBold = GoogleFonts.poppins(
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.5,
    letterSpacing: 0.50 * 24 / 100,
  );

  static TextStyle linkMedium = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.75 * 16 / 100,
  );

  static TextStyle textMedium = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.75 * 16 / 100,
  );

  static TextStyle textSmall = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    letterSpacing: 0.85 * 14 / 100,
  );

  static TextStyle labelLarge = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.12,
  );
}
