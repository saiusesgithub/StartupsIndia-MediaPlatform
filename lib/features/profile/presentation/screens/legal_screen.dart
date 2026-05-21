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
                            'Last updated: May 19, 2026',
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
    'Privacy Policy',
    'Last Updated: November 10, 2025\n\n1. Introduction\nWelcome to Startup India Incubation ("we," "our," or "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website and use our services.',
  ),
  (
    '2. Information We Collect',
    '2.1 Personal Information\nWe may collect personal information that you voluntarily provide to us when you: register for an account; apply for incubation programs; subscribe to our newsletter; contact us for support; or participate in surveys or promotions. This information may include name and contact information (email, phone number), business information (company name, industry, stage), educational background, professional experience, and payment information.\n\n2.2 Automatically Collected Information\nWhen you visit our website, we automatically collect certain information about your device, including IP address, browser type, operating system, access times, pages viewed, and referring website addresses.',
  ),
  (
    '3. How We Use Your Information',
    'We use the information we collect or receive to: process your applications and registrations; provide and maintain our services; send you administrative information; send you marketing and promotional communications; respond to your inquiries and provide customer support; monitor and analyze usage and trends; detect, prevent, and address technical issues; and improve our website and services.',
  ),
  (
    '4. Information Sharing and Disclosure',
    'We may share your information in the following situations: with service providers who perform services on our behalf; in connection with any merger, sale of company assets, financing, or acquisition; with your consent for any other purpose; or when required by law or to protect our rights.',
  ),
  (
    '5. Data Security',
    'We implement appropriate technical and organizational security measures to protect your personal information. However, no electronic transmission or storage method is 100% secure, and we cannot guarantee absolute security.',
  ),
  (
    '6. Your Privacy Rights',
    'Depending on your location, you may have the right to access your personal information; correct inaccurate or incomplete information; request deletion of your information; object to or restrict processing; request data portability; or withdraw consent.',
  ),
  (
    '7. Cookies and Tracking Technologies',
    'We use cookies and similar tracking technologies to track activity on our website and hold certain information. You can instruct your browser to refuse all cookies or indicate when a cookie is being sent. For more information, please see our Cookie Policy.',
  ),
  (
    '8. Third-Party Links',
    'Our website may contain links to third-party websites. We are not responsible for the privacy practices of these external sites. We encourage you to read their privacy policies.',
  ),
  (
    '9. Children\'s Privacy',
    'Our services are not directed to individuals under 18 years of age. We do not knowingly collect personal information from children under 18.',
  ),
  (
    '10. Changes to This Privacy Policy',
    'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
  ),
  (
    '11. Contact Us',
    'If you have questions about this Privacy Policy, please contact us at: Email: startupsindiaofficial@gmail.com\nPhone: +91 9599033080\nAddress: 3rd Floor, United Arcade, Pillar No. 143, Shop.No.8, Attapur, Hyderabad, Telangana 500048',
  ),
];

// ── Terms of Service content ───────────────────────────────────────────────────

const _termsSections = [
  (
    '1. Acceptance of Terms',
    'By using the StartupsIndia app, you agree to be bound by these Terms of Service. If you do not agree, please do not use the app.',
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
    'The StartupsIndia app and its original content, features, and functionality are owned by StartupsIndia and are protected by applicable intellectual property laws.',
  ),
  (
    '6. Termination',
    'We reserve the right to terminate or suspend accounts that violate these terms. You may delete your account at any time by contacting our support team.',
  ),
  (
    '7. Limitation of Liability',
    'To the maximum extent permitted by law, StartupsIndia shall not be liable for any indirect, incidental, or consequential damages arising from your use of the platform.',
  ),
  (
    '8. Changes to Terms',
    'We may update these Terms from time to time. Continued use of the app after changes constitutes acceptance of the new Terms. We will notify users of significant changes.',
  ),
];
