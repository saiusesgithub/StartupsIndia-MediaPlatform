import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/providers/theme_service_provider.dart';
import '../../../../theme/style_guide.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeServiceProvider);
    final isDark = themeMode == ThemeMode.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    Text(
                      'Settings',
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
            ),

            // ── Account ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                isDark: isDark,
                label: 'Account',
                children: [
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primaryDefault,
                    label: 'Edit Profile',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  _RowDivider(isDark: isDark),
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF5C6BC0),
                    label: 'Change Password',
                    onTap: () => Navigator.pushNamed(context, '/change-password'),
                  ),
                  _RowDivider(isDark: isDark),
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.delete_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    label: 'Delete Account',
                    onTap: () =>
                        Navigator.pushNamed(context, '/delete-account'),
                  ),
                ],
              ),
            ),

            // ── Preferences ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                isDark: isDark,
                label: 'Preferences',
                children: [
                  _SwitchRow(
                    isDark: isDark,
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF9C27B0),
                    label: 'Dark Mode',
                    value: isDark,
                    onChanged: (v) =>
                        ref.read(themeServiceProvider.notifier).setDarkMode(v),
                  ),
                  _RowDivider(isDark: isDark),
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFFF57C00),
                    label: 'Notifications',
                    onTap: () =>
                        Navigator.pushNamed(context, '/notification-settings'),
                  ),
                ],
              ),
            ),

            // ── Support ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Section(
                isDark: isDark,
                label: 'Support',
                children: [
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF2196F3),
                    label: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, '/help-support'),
                  ),
                  _RowDivider(isDark: isDark),
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.policy_outlined,
                    iconColor: const Color(0xFF4CAF50),
                    label: 'Privacy Policy',
                    onTap: () =>
                        Navigator.pushNamed(context, '/privacy-policy'),
                  ),
                  _RowDivider(isDark: isDark),
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF00BCD4),
                    label: 'Terms of Service',
                    onTap: () =>
                        Navigator.pushNamed(context, '/terms-of-service'),
                  ),
                  _RowDivider(isDark: isDark),
                  _SettingsRow(
                    isDark: isDark,
                    icon: Icons.info_outline_rounded,
                    iconColor: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleButtonText,
                    label: 'About App',
                    trailing: Text(
                      'v1.0.0',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                    showChevron: false,
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),

            // ── Log Out ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: GestureDetector(
                  onTap: () => _confirmLogout(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Log Out',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                'Log Out?',
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 18,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out\nof your account?',
                textAlign: TextAlign.center,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.grayscaleLine,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Log Out',
                          textAlign: TextAlign.center,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

}

// ── Section card ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final bool isDark;
  final String label;
  final List<Widget> children;

  const _Section({
    required this.isDark,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: AppTypography.textSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.showChevron = true,
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
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
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

// ── Switch row ────────────────────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryDefault,
            activeTrackColor: AppColors.primaryDefault.withValues(alpha: 0.3),
            inactiveThumbColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleButtonText,
            inactiveTrackColor: isDark
                ? AppColors.darkBorder
                : AppColors.grayscaleLine,
          ),
        ],
      ),
    );
  }
}

// ── Thin divider ──────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  final bool isDark;

  const _RowDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      endIndent: 0,
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
    );
  }
}
