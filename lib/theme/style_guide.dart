import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The central source of truth for all foundational design tokens
/// extracted from Figma. If the client wants to change "Brand Blue" later,
/// simply change it here and the entire app will update.
class AppColors {
  // Brand & Primary
  static const Color primaryDefault = Color(0xFF1877F2); // "Brand Blue"

  // Grayscale Palette
  static const Color grayscaleWhite = Color(0xFFFFFFFF);
  static const Color grayscaleTitleActive = Color(0xFF050505);
  static const Color grayscaleBodyText = Color(0xFF4E4B66);
  static const Color grayscaleButtonText = Color(0xFF667080);
  static const Color grayscaleSecondaryButton = Color(0xFFEEF1F4);
  static const Color grayscaleLine = Color(0xFFE4E4E4);
  static const Color grayscaleInputBackground = Color(0xFFFAFAFA);

  // Status & Feedback
  static const Color errorDefault = Color(0xFFED2E7E);
  static const Color successDefault = Color(0xFF00BA88);
  static const Color warningDefault = Color(0xFFF4B740);
}

class AppTypography {
  // Extracting typography styles globally from Figma
  static TextStyle displayMediumBold = GoogleFonts.poppins(
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.5,
    letterSpacing: 0.12, // Calculated based on Figma % spacing conventions
  );

  static TextStyle linkMedium = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.12,
  );

  static TextStyle textMedium = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.12,
  );

  static TextStyle textSmall = GoogleFonts.poppins(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.5,
    letterSpacing: 0.12,
  );
  
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.12,
  );
}
