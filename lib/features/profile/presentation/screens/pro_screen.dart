import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        surfaceTintColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'StartupsIndia Pro',
          style: AppTypography.displaySmallBold.copyWith(
            fontSize: 17,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryDefault,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'StartupsIndia Pro',
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 26,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Coming Soon',
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryDefault,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Analytics, priority features, early access to funding rounds, and a lot more — exclusively for Pro members.',
                textAlign: TextAlign.center,
                style: AppTypography.textMedium.copyWith(
                  fontSize: 15,
                  height: 1.55,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
              const SizedBox(height: 40),
              _FeatureRow(
                icon: Icons.analytics_outlined,
                label: 'Advanced analytics',
                isDark: isDark,
              ),
              _FeatureRow(
                icon: Icons.bolt_rounded,
                label: 'Priority content & early access',
                isDark: isDark,
              ),
              _FeatureRow(
                icon: Icons.people_outline_rounded,
                label: 'Exclusive founder networks',
                isDark: isDark,
              ),
              _FeatureRow(
                icon: Icons.notifications_active_outlined,
                label: 'Real-time funding alerts',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDefault),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: AppTypography.textSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
        ],
      ),
    );
  }
}
