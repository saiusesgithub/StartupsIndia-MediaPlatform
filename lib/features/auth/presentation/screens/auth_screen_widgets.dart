import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/style_guide.dart';

/// Dark brand header used at the top of Login & Signup screens.
/// Features the StartupsIndia logo mark + title + subtitle.
class BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const BrandHeader({required this.title, required this.subtitle});

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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.grayscaleLine, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: AppTypography.textSmall.copyWith(
              color: AppColors.grayscaleButtonText,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.grayscaleLine, thickness: 1),
        ),
      ],
    );
  }
}

/// Google Sign-In button with proper Google branding style.
class GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.grayscaleLine, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
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
                      color: AppColors.grayscaleTitleActive,
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
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$question ',
          style: AppTypography.textSmall.copyWith(
            color: AppColors.grayscaleBodyText,
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
