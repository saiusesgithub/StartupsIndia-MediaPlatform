import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/style_guide.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../explore/presentation/screens/media_feed_screen.dart';
import '../../../profile/presentation/screens/personal_profile_screen.dart';
import 'home_screen.dart';

// ── Build menu items ───────────────────────────────────────────────────────────

const _kBuildItems = [
  (
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFFE8341C),
    label: 'Startup Ecosystem',
    url: 'https://startupindia.gov.in',
  ),
  (
    icon: Icons.event_rounded,
    color: Color(0xFF5C6BC0),
    label: 'Events',
    url: 'https://startupindia.gov.in/content/sipp/en/events.html',
  ),
  (
    icon: Icons.people_rounded,
    color: Color(0xFF2196F3),
    label: 'Mentorship',
    url: 'https://startupindia.gov.in/content/sipp/en/mentors.html',
  ),
  (
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF4CAF50),
    label: 'Funding',
    url: 'https://startupindia.gov.in/content/sipp/en/startup-funding.html',
  ),
];

// ── Scaffold ───────────────────────────────────────────────────────────────────

class MainAppScaffold extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainAppScaffold({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends ConsumerState<MainAppScaffold> {
  late int _navIndex;
  bool _showBuildMenu = false;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex == 2 ? 0 : widget.initialIndex;
  }

  void _onNavTap(int index) {
    if (index == 2) {
      setState(() => _showBuildMenu = !_showBuildMenu);
    } else {
      setState(() {
        _navIndex = index;
        _showBuildMenu = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) setState(() => _showBuildMenu = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(fcmTokenSyncProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_showBuildMenu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showBuildMenu) {
          setState(() => _showBuildMenu = false);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        body: Stack(
          children: [
            // ── Main content ───────────────────────────────────────────
            IndexedStack(
              index: _navIndex,
              children: const [
                HomeScreen(),
                MediaFeedScreen(),
                SizedBox.shrink(), // Build — never shown (menu only)
                CommunityScreen(),
                PersonalProfileScreen(),
              ],
            ),

            // ── Build menu overlay ─────────────────────────────────────
            if (_showBuildMenu) ...[
              // Scrim
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showBuildMenu = false),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child:
                        Container(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                ),
              ),

              // Bubble (above nav bar)
              Positioned(
                left: 24,
                right: 24,
                bottom: 12,
                child: _BuildBubble(
                  isDark: isDark,
                  onTap: _launchUrl,
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: _CustomBottomNav(
          currentIndex: _navIndex,
          isBuildOpen: _showBuildMenu,
          isDark: isDark,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ── Speech-bubble menu ─────────────────────────────────────────────────────────

class _BuildBubble extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onTap;

  const _BuildBubble({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border =
        isDark ? AppColors.darkBorder : const Color(0xFFE8E8E8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_kBuildItems.length, (i) {
              final item = _kBuildItems[i];
              final isLast = i == _kBuildItems.length - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BuildMenuItem(
                    icon: item.icon,
                    color: item.color,
                    label: item.label,
                    isDark: isDark,
                    onTap: () => onTap(item.url),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: border,
                    ),
                ],
              );
            }),
          ),
        ),

        // Arrow pointing down toward Build button
        CustomPaint(
          painter: _TrianglePainter(color: bg, border: border),
          size: const Size(22, 11),
        ),
      ],
    );
  }
}

class _BuildMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _BuildMenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
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

// Triangle painter for the speech-bubble tail
class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color border;

  const _TrianglePainter({required this.color, required this.border});

  @override
  void paint(Canvas canvas, Size size) {
    // Border triangle (slightly larger, drawn first)
    final borderPaint = Paint()
      ..color = border
      ..style = PaintingStyle.fill;
    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height + 1)
      ..close();
    canvas.drawPath(borderPath, borderPaint);

    // Fill triangle
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final fillPath = Path()
      ..moveTo(1, 0)
      ..lineTo(size.width - 1, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color || old.border != border;
}

// ── Custom bottom nav bar ──────────────────────────────────────────────────────

class _CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isBuildOpen;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _CustomBottomNav({
    required this.currentIndex,
    required this.isBuildOpen,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final border =
        isDark ? AppColors.darkBorder : AppColors.grayscaleLine;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Explore',
                index: 1,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              // Build — red circle FAB
              _BuildNavButton(
                isOpen: isBuildOpen,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Community',
                index: 3,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final color = isActive
        ? AppColors.primaryDefault
        : (isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildNavButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _BuildNavButton({required this.isOpen, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isOpen
                    ? AppColors.primaryDefault.withValues(alpha: 0.85)
                    : AppColors.primaryDefault,
                shape: BoxShape.circle,
              ),
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0, // 45° when open → becomes ×
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Build',
              style: AppTypography.textSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isOpen
                    ? AppColors.primaryDefault
                    : AppColors.grayscaleButtonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
