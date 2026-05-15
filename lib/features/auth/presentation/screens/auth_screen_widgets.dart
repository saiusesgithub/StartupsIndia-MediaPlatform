import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/style_guide.dart';

/// Centered brand logo mark — icon badge + wordmark.
/// Used on Splash and Welcome screens. [scale] multiplies all dimensions.
class AppLogoMark extends StatelessWidget {
  final double scale;
  const AppLogoMark({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxSize = 76.0 * scale;
    final iconSize = 40.0 * scale;
    final radius = 22.0 * scale;
    final fontSize = 30.0 * scale;
    final gap = 14.0 * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: AppColors.primaryDefault,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDefault
                    .withValues(alpha: isDark ? 0.35 : 0.20),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.rocket_launch_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        SizedBox(height: gap),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Startups',
                style: AppTypography.displaySmallBold.copyWith(
                  color: AppColors.primaryDefault,
                  fontSize: fontSize,
                ),
              ),
              TextSpan(
                text: 'India',
                style: AppTypography.displaySmallBold.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                  fontSize: fontSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dark brand header used at the top of Login & Signup screens.
/// Features the StartupsIndia logo mark + title + subtitle.
class BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const BrandHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, topPadding + 28, 28, 28),
      color: AppColors.darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo mark
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Startups',
                      style: AppTypography.linkMedium.copyWith(
                        color: AppColors.primaryDefault,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: 'India',
                      style: AppTypography.linkMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.displaySmallBold.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.textSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Red primary CTA button with loading state.
class PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDefault,
          disabledBackgroundColor: AppColors.primaryDefault.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: AppTypography.linkMedium.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

/// "— or continue with —" divider row.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText;

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: AppTypography.textSmall.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}

/// Google Sign-In button — adapts to light and dark theme.
class GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleButton({super.key, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.google,
                    color: Color(0xFFDB4437),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bottom row for switching between Login ↔ Sign Up.
class AuthSwitchRow extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthSwitchRow({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$question ',
          style: AppTypography.textSmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: AppTypography.textSmall.copyWith(
              color: AppColors.primaryDefault,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
