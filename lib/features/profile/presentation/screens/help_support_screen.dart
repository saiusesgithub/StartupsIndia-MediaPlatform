import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/style_guide.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final Set<int> _expanded = {};

  static const _faqs = [
    (
      q: 'How do I follow a news source?',
      a:
          'Go to the Explore tab, find a source you like, and tap the "Follow" button on their profile page. You\'ll then see their articles in your feed.',
    ),
    (
      q: 'How do I save articles for later?',
      a:
          'Tap the bookmark icon on any article card or inside the article detail view. Saved articles appear in your Profile under the Saved tab.',
    ),
    (
      q: 'Why am I not receiving notifications?',
      a:
          'Check your notification settings in Settings → Notifications. Also make sure you\'ve granted notification permissions to the app in your device settings.',
    ),
    (
      q: 'How do I change my profile photo?',
      a:
          'Go to Settings → Edit Profile. Tap the camera icon on your avatar to pick a new photo from your gallery.',
    ),
    (
      q: 'How do I delete my account?',
      a:
          'Account deletion requests can be submitted by emailing support@startupsindia.app. We\'ll process your request within 7 business days.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildContactCard(isDark),
                          const SizedBox(height: 24),
                          _sectionLabel('Frequently Asked Questions', isDark),
                          const SizedBox(height: 10),
                          _buildFaqCard(isDark),
                          const SizedBox(height: 24),
                          _sectionLabel('Resources', isDark),
                          const SizedBox(height: 10),
                          _buildResourcesCard(isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
              'Help & Support',
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

  Widget _buildContactCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: AppColors.primaryDefault, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Support',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'We respond within 24 hours',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ContactButton(
            icon: Icons.email_outlined,
            label: 'Email Us',
            subtitle: 'support@startupsindia.app',
            isDark: isDark,
            onTap: () => _launch('mailto:support@startupsindia.app'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(bool isDark) {
    final bg = isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final border = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: List.generate(_faqs.length, (i) {
          final isOpen = _expanded.contains(i);
          final isLast = i == _faqs.length - 1;
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.only(
                  topLeft: i == 0
                      ? const Radius.circular(16)
                      : Radius.zero,
                  topRight: i == 0
                      ? const Radius.circular(16)
                      : Radius.zero,
                  bottomLeft: isLast && !isOpen
                      ? const Radius.circular(16)
                      : Radius.zero,
                  bottomRight: isLast && !isOpen
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                onTap: () => setState(() {
                  if (isOpen) {
                    _expanded.remove(i);
                  } else {
                    _expanded.add(i);
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _faqs[i].q,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleButtonText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isOpen)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    _faqs[i].a,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 13,
                      height: 1.55,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: border,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildResourcesCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
      ),
      child: Column(
        children: [
          _ResourceRow(
            isDark: isDark,
            icon: Icons.public_rounded,
            iconColor: const Color(0xFF2196F3),
            label: 'Startup Ecosystem',
            onTap: () => _launch('https://www.startupsindia.in'),
          ),
          Divider(
            height: 1,
            indent: 66,
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
          _ResourceRow(
            isDark: isDark,
            icon: Icons.event_rounded,
            iconColor: const Color(0xFF4CAF50),
            label: 'Events',
            onTap: () => _launch('https://www.startupsindia.in/events'),
          ),
          Divider(
            height: 1,
            indent: 66,
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
          _ResourceRow(
            isDark: isDark,
            icon: Icons.support_agent_rounded,
            iconColor: const Color(0xFF9C27B0),
            label: 'Mentorship',
            onTap: () => _launch('https://www.startupsindia.in/mentors'),
          ),
          Divider(
            height: 1,
            indent: 66,
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
          _ResourceRow(
            isDark: isDark,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFFFF9800),
            label: 'Funding',
            onTap: () => _launch('https://www.startupsindia.in/investors'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.grayscaleBodyText,
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkBackground
              : AppColors.grayscaleSecondaryButton,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      )),
                  Text(subtitle,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleButtonText),
          ],
        ),
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ResourceRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleButtonText),
          ],
        ),
      ),
    );
  }
}
