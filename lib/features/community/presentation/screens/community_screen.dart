import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Community',
                    style: AppTypography.displaySmallBold.copyWith(
                      fontSize: 22,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryDefault.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_outline_rounded,
                          size: 36,
                          color: AppColors.primaryDefault,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Community Hub',
                        style: AppTypography.displaySmallBold.copyWith(
                          fontSize: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect with founders, mentors,\nand investors — coming soon.',
                        textAlign: TextAlign.center,
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                        ),
                      ),
                      if (isGuest) ...[
                        const SizedBox(height: 36),
                        _GuestCta(isDark: isDark),
                      ],
                    ],
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

class _GuestCta extends StatelessWidget {
  final bool isDark;

  const _GuestCta({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Create an account to be notified\nwhen this launches.',
          textAlign: TextAlign.center,
          style: AppTypography.textSmall.copyWith(
            fontSize: 13,
            height: 1.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/signup'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryDefault,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Create Free Account',
                textAlign: TextAlign.center,
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/login'),
          child: Text(
            'Already have an account? Log In',
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDefault,
            ),
          ),
        ),
      ],
    );
  }
}
