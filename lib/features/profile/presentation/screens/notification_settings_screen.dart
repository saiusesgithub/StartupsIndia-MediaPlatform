import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _breakingNews = true;
  bool _followedSources = true;
  bool _communityActivity = false;
  bool _weeklyDigest = true;
  bool _fundingAlerts = false;
  bool _pushEnabled = true;

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
                          _NotifSection(
                            label: 'General',
                            isDark: isDark,
                            children: [
                              _SwitchTile(
                                isDark: isDark,
                                icon: Icons.notifications_active_rounded,
                                iconColor: AppColors.primaryDefault,
                                label: 'Push Notifications',
                                subtitle: 'Allow all notifications from the app',
                                value: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _pushEnabled = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _NotifSection(
                            label: 'News & Content',
                            isDark: isDark,
                            children: [
                              _SwitchTile(
                                isDark: isDark,
                                icon: Icons.flash_on_rounded,
                                iconColor: AppColors.primaryDefault,
                                label: 'Breaking News',
                                subtitle: 'Instant alerts for major startup events',
                                value: _breakingNews && _pushEnabled,
                                enabled: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _breakingNews = v),
                              ),
                              _Divider(isDark: isDark),
                              _SwitchTile(
                                isDark: isDark,
                                icon: Icons.newspaper_rounded,
                                iconColor: const Color(0xFF2196F3),
                                label: 'Followed Sources',
                                subtitle: 'New articles from sources you follow',
                                value: _followedSources && _pushEnabled,
                                enabled: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _followedSources = v),
                              ),
                              _Divider(isDark: isDark),
                              _SwitchTile(
                                isDark: isDark,
                                icon: Icons.account_balance_wallet_rounded,
                                iconColor: const Color(0xFF4CAF50),
                                label: 'Funding Alerts',
                                subtitle: 'New funding rounds and investments',
                                value: _fundingAlerts && _pushEnabled,
                                enabled: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _fundingAlerts = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _NotifSection(
                            label: 'Community',
                            isDark: isDark,
                            children: [
                              _SwitchTile(
                                isDark: isDark,
                                icon: Icons.people_rounded,
                                iconColor: const Color(0xFF9C27B0),
                                label: 'Community Activity',
                                subtitle: 'Replies, mentions, and reactions',
                                value: _communityActivity && _pushEnabled,
                                enabled: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _communityActivity = v),
                              ),
                              _Divider(isDark: isDark),
                              _SwitchTile(
                                isDark: isDark,
                                icon: Icons.mail_outline_rounded,
                                iconColor: const Color(0xFFF57C00),
                                label: 'Weekly Digest',
                                subtitle: 'Top stories and trends every Sunday',
                                value: _weeklyDigest && _pushEnabled,
                                enabled: _pushEnabled,
                                onChanged: (v) =>
                                    setState(() => _weeklyDigest = v),
                              ),
                            ],
                          ),
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
            icon:
                Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          ),
          Expanded(
            child: Text(
              'Notifications',
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

class _NotifSection extends StatelessWidget {
  final String label;
  final bool isDark;
  final List<Widget> children;

  const _NotifSection({
    required this.label,
    required this.isDark,
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
            color:
                isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled
        ? (isDark
            ? AppColors.darkTextPrimary
            : AppColors.grayscaleTitleActive)
        : (isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (enabled ? iconColor : AppColors.grayscaleButtonText)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: enabled ? iconColor : AppColors.grayscaleButtonText,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.primaryDefault,
            activeTrackColor:
                AppColors.primaryDefault.withValues(alpha: 0.3),
            inactiveThumbColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleButtonText,
            inactiveTrackColor:
                isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
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
      indent: 68,
      endIndent: 0,
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
    );
  }
}
