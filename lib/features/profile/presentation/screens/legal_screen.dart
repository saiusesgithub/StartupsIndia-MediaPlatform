import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

enum LegalType { privacyPolicy, termsOfService }

class LegalScreen extends StatelessWidget {
  final LegalType type;

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = type == LegalType.privacyPolicy
        ? 'Privacy Policy'
        : 'Terms of Service';
    final sections = type == LegalType.privacyPolicy
        ? _privacySections
        : _termsSections;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, title),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Last updated chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.grayscaleWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.grayscaleLine,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last updated: May 2025',
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.grayscaleBodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...sections.map(
                      (s) => _LegalSection(
                        heading: s.$1,
                        body: s.$2,
                        isDark: isDark,
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

  Widget _buildHeader(BuildContext context, bool isDark, String title) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String heading;
  final String body;
  final bool isDark;

  const _LegalSection({
    required this.heading,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: AppTypography.textSmall.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                height: 1.6,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Privacy Policy content ─────────────────────────────────────────────────────

const _privacySections = [
  (
    '1. Information We Collect',
    'We collect information you provide directly, such as your name, email address, phone number, and profile photo when you create an account. We also collect usage data including articles you read, sources you follow, and interactions within the app.',
  ),
  (
    '2. How We Use Your Information',
    'We use your information to personalise your news feed, send notifications you have opted into, improve our services, and ensure platform security. We do not sell your personal data to third parties.',
  ),
  (
    '3. Data Sharing',
    'We may share anonymised, aggregated data with analytics partners to understand usage trends. Individual user data is never shared without your explicit consent, except as required by law.',
  ),
  (
    '4. Data Retention',
    'We retain your data for as long as your account is active. You may request deletion of your account and associated data by contacting support@startupsindia.app.',
  ),
  (
    '5. Security',
    'We use industry-standard encryption and security practices to protect your data. Firebase Authentication and Cloud Firestore are used with strict security rules to prevent unauthorised access.',
  ),
  (
    '6. Your Rights',
    'You have the right to access, correct, or delete your personal data. You may also opt out of marketing communications at any time through the app settings.',
  ),
  (
    '7. Contact Us',
    'If you have questions about this Privacy Policy, please contact us at privacy@startupsindia.app or through the Help & Support section in the app.',
  ),
];

// ── Terms of Service content ───────────────────────────────────────────────────

const _termsSections = [
  (
    '1. Acceptance of Terms',
    'By using the Startups India app, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.',
  ),
  (
    '2. User Accounts',
    'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorised use of your account.',
  ),
  (
    '3. Acceptable Use',
    'You agree not to misuse the platform, post harmful content, violate any applicable laws, or attempt to gain unauthorised access to any part of the service.',
  ),
  (
    '4. Content',
    'News content on the platform is sourced from verified publishers. We do not guarantee the accuracy of third-party content. User-generated content (comments, profile info) remains the responsibility of the user.',
  ),
  (
    '5. Intellectual Property',
    'The Startups India app and its original content, features, and functionality are owned by Startups India and are protected by applicable intellectual property laws.',
  ),
  (
    '6. Termination',
    'We reserve the right to terminate or suspend accounts that violate these terms. You may delete your account at any time by contacting our support team.',
  ),
  (
    '7. Limitation of Liability',
    'To the maximum extent permitted by law, Startups India shall not be liable for any indirect, incidental, or consequential damages arising from your use of the platform.',
  ),
  (
    '8. Changes to Terms',
    'We may update these Terms from time to time. Continued use of the app after changes constitutes acceptance of the new Terms. We will notify users of significant changes.',
  ),
];
