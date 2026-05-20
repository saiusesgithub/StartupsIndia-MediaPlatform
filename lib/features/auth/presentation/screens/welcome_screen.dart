import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/style_guide.dart';
import 'auth_screen_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero area ────────────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Soft tinted circle background (light mode)
                    if (!isDark)
                      Container(
                        width: 280,
                        height: 280,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySurface,
                        ),
                      ),

                    // Radial glow top-right (dark mode)
                    if (isDark)
                      Positioned(
                        top: -40,
                        right: -40,
                        child: _GlowCircle(
                          size: 240,
                          color: AppColors.primaryDefault.withValues(alpha: 0.18),
                        ),
                      ),

                    // Concentric decorative rings
                    for (final diameter in [180.0, 248.0, 316.0])
                      Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryDefault.withValues(
                              alpha: isDark ? 0.07 : 0.06,
                            ),
                            width: 1,
                          ),
                        ),
                      ),

                    // Logo mark — slightly larger than splash
                    const AppLogoMark(scale: 1.12),
                  ],
                ),
              ),

              // ── Content & CTAs ───────────────────────────────────────────
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Build Your\nStartup Journey',
                        style: AppTypography.displaySmallBold.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                          fontSize: 30,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Learn. Build. Network. Fund.',
                        style: AppTypography.textMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),

                      // Login
                      PrimaryButton(
                        label: 'Login',
                        isLoading: false,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/login'),
                      ),
                      const SizedBox(height: 14),

                      // Create Account
                      _SecondaryButton(
                        label: 'Create Account',
                        isDark: isDark,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/role-selection'),
                      ),
                      const SizedBox(height: 6),

                      // Continue as Guest
                      TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (_) => false,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleButtonText,
                          overlayColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Continue as Guest',
                          style: AppTypography.textSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleButtonText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outlined secondary button ─────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: isDark
              ? AppColors.darkTextPrimary
              : AppColors.grayscaleTitleActive,
          overlayColor: AppColors.primaryDefault.withValues(alpha: 0.05),
        ),
        child: Text(
          label,
          style: AppTypography.linkMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── Radial glow decoration ─────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
