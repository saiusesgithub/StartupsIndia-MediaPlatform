import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/style_guide.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAppCard(isDark),
                    const SizedBox(height: 24),
                    _buildLinksCard(isDark),
                    const SizedBox(height: 24),
                    _buildTechCard(isDark),
                    const SizedBox(height: 24),
                    _buildFooter(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.grayscaleWhite;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;

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
              'About App',
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

  Widget _buildAppCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/startupsindia/Icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'StartupsIndia',
            style: AppTypography.textSmall.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your startup news companion',
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryDefault.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Version 1.0.0',
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard(bool isDark) {
    return _Card(
      isDark: isDark,
      label: 'Connect',
      children: [
        _LinkRow(
          isDark: isDark,
          icon: Icons.language_rounded,
          iconColor: const Color(0xFF2196F3),
          label: 'Official Website',
          url: 'https://www.startupsindia.in/',
        ),
        _Divider(isDark: isDark),
        _LinkRow(
          isDark: isDark,
          icon: Icons.play_circle_outline_rounded,
          iconColor: const Color(0xFFFF0000),
          label: 'YouTube',
          url: 'https://www.youtube.com/@startupsindiaofficial',
        ),
        _Divider(isDark: isDark),
        _LinkRow(
          isDark: isDark,
          icon: Icons.camera_alt_outlined,
          iconColor: const Color(0xFFE1306C),
          label: 'Instagram',
          url: 'https://www.instagram.com/startupsindia_official',
        ),
        _Divider(isDark: isDark),
        _LinkRow(
          isDark: isDark,
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFF0077B5),
          label: 'LinkedIn',
          url: 'https://www.linkedin.com/company/startupsindia/',
        ),
      ],
    );
  }

  Widget _buildTechCard(bool isDark) {
    return _Card(
      isDark: isDark,
      label: 'Built With',
      children: [
        _TechRow(isDark: isDark, label: 'Framework', value: 'Flutter 3.x'),
        _Divider(isDark: isDark),
        _TechRow(isDark: isDark, label: 'Backend', value: 'Firebase'),
        _Divider(isDark: isDark),
        _TechRow(isDark: isDark, label: 'State Management', value: 'Riverpod'),
        _Divider(isDark: isDark),
        _MadeWithFlutter(isDark: isDark),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Text(
      '© 2026 StartupsIndia. All rights reserved.',
      textAlign: TextAlign.center,
      style: AppTypography.textSmall.copyWith(
        fontSize: 12,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.grayscaleButtonText,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final String label;
  final List<Widget> children;

  const _Card({
    required this.isDark,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
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
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String url;

  const _LinkRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
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
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
          ],
        ),
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;

  const _TechRow({
    required this.isDark,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.textSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.textSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
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

class _MadeWithFlutter extends StatelessWidget {
  final bool isDark;
  const _MadeWithFlutter({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            'Made with',
            style: AppTypography.textSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF54C5F8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF54C5F8).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flutter_dash,
                  color: Color(0xFF54C5F8),
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Flutter',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF54C5F8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
    );
  }
}
