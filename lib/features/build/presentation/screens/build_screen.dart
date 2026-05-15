import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class BuildScreen extends StatelessWidget {
  const BuildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    'Build',
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDefault.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rocket_launch_outlined,
                        size: 36,
                        color: AppColors.primaryDefault,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Build Hub',
                      style: AppTypography.displaySmallBold.copyWith(
                        fontSize: 20,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tools, resources, and playbooks\nfor founders — coming soon.',
                      textAlign: TextAlign.center,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
