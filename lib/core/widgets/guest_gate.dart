import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/style_guide.dart';

// ── Section blur overlay ───────────────────────────────────────────────────────
// Wrap any fixed-height section with this to blur it and show a sign-up CTA.

class GuestBlur extends StatelessWidget {
  final Widget child;
  final String label;
  final BorderRadius borderRadius;

  const GuestBlur({
    super.key,
    required this.child,
    this.label = 'Sign Up Free →',
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.52),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: const Alignment(0, 0.35),
                    child: _UnlockPill(label: label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlockPill extends StatelessWidget {
  final String label;

  const _UnlockPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/signup'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.primaryDefault,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDefault.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen feed gate (media feed 3rd page) ────────────────────────────────

class GuestFeedGate extends StatelessWidget {
  const GuestFeedGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A0A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo (dark background variant)
                Image.asset(
                  'assets/startupsindia/logo_dark.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),

                // Lock icon circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDefault.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryDefault.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.primaryDefault, size: 30),
                ),
                const SizedBox(height: 28),

                Text(
                  "You've seen the preview",
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 22,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a free account to keep scrolling,\nfollow topics, and never miss a story.',
                  textAlign: TextAlign.center,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 14,
                    color: Colors.white60,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 40),

                // Create Account CTA
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDefault,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryDefault.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Create Free Account',
                        textAlign: TextAlign.center,
                        style: AppTypography.displaySmallBold.copyWith(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Log In secondary
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'Already have an account? Log In',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 13,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Guest profile screen ───────────────────────────────────────────────────────

class GuestProfileScreen extends StatelessWidget {
  final bool isDark;

  const GuestProfileScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Profile card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.grayscaleWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.grayscaleLine,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Cover strip
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        child: Container(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryDefault
                                    .withValues(alpha: isDark ? 0.3 : 0.15),
                                const Color(0xFF1A0A2E)
                                    .withValues(alpha: isDark ? 0.6 : 0.25),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      // Avatar + name
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.grayscaleSecondaryButton,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.grayscaleWhite,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primaryDefault,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Guest',
                              style: AppTypography.displaySmallBold.copyWith(
                                fontSize: 20,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.grayscaleTitleActive,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@guest',
                              style: AppTypography.textSmall.copyWith(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleBodyText,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Stats row (all zeros)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  _GuestStat(label: 'Posts', isDark: isDark),
                                  _GuestStatDiv(isDark: isDark),
                                  _GuestStat(
                                      label: 'Followers', isDark: isDark),
                                  _GuestStatDiv(isDark: isDark),
                                  _GuestStat(
                                      label: 'Following', isDark: isDark),
                                  _GuestStatDiv(isDark: isDark),
                                  _GuestStat(
                                      label: 'Communities', isDark: isDark),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Join CTA card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.grayscaleWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.grayscaleLine,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryDefault.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded,
                            color: AppColors.primaryDefault, size: 26),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join StartupsIndia',
                        style: AppTypography.displaySmallBold.copyWith(
                          fontSize: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get your own profile, follow founders,\nsave articles, and track your journey.',
                        textAlign: TextAlign.center,
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 13,
                          height: 1.55,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Create Account button
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDefault,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Create Free Account',
                              textAlign: TextAlign.center,
                              style: AppTypography.displaySmallBold.copyWith(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Log In secondary
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/login'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.grayscaleLine,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Log In',
                              textAlign: TextAlign.center,
                              style: AppTypography.displaySmallBold.copyWith(
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.grayscaleTitleActive,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestStat extends StatelessWidget {
  final String label;
  final bool isDark;

  const _GuestStat({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '0',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 18,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestStatDiv extends StatelessWidget {
  final bool isDark;

  const _GuestStatDiv({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
    );
  }
}
