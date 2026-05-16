import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/style_guide.dart';

// ── Role data ──────────────────────────────────────────────────────────────────

class _Role {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _Role({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const _roles = [
  _Role(
    id: 'student',
    title: 'Student',
    description: 'Learning, exploring and building my skills',
    icon: Icons.school_rounded,
  ),
  _Role(
    id: 'founder',
    title: 'Founder',
    description: 'Building my startup and looking for resources',
    icon: Icons.rocket_launch_rounded,
  ),
  _Role(
    id: 'mentor',
    title: 'Mentor',
    description: 'Guiding startups and sharing my expertise',
    icon: Icons.psychology_rounded,
  ),
  _Role(
    id: 'investor',
    title: 'Investor',
    description: 'Investing in promising startups',
    icon: Icons.trending_up_rounded,
  ),
  _Role(
    id: 'college',
    title: 'College',
    description: 'Representing my college or organization',
    icon: Icons.account_balance_rounded,
  ),
  _Role(
    id: 'startup_enthusiast',
    title: 'Startup Enthusiast',
    description: 'Passionate about startups and innovation',
    icon: Icons.favorite_rounded,
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _continue() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    Navigator.pushNamed(
      context,
      currentUser == null ? '/signup' : '/interest-selection',
      arguments: _selectedRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bar
                    _StepProgressBar(current: 1, total: 2, isDark: isDark),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Step 1 of 2',
                        style: AppTypography.textSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    RichText(
                      text: TextSpan(
                        style: AppTypography.displaySmallBold.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                          fontSize: 26,
                        ),
                        children: [
                          const TextSpan(text: 'Choose '),
                          TextSpan(
                            text: 'your',
                            style: AppTypography.displaySmallBold.copyWith(
                              color: AppColors.primaryDefault,
                              fontSize: 26,
                            ),
                          ),
                          const TextSpan(text: ' role'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us personalize your experience and content.',
                      style: AppTypography.textSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Role grid ────────────────────────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _roles.map((role) {
                    return _RoleCard(
                      role: role,
                      isSelected: _selectedRole == role.id,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedRole = role.id),
                    );
                  }).toList(),
                ),
              ),

              // ── Bottom CTA ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedRole != null ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDefault,
                          disabledBackgroundColor: AppColors.primaryDefault
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: AppTypography.linkMedium.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose carefully. Your role cannot be changed after sign-up.',
                      textAlign: TextAlign.center,
                      style: AppTypography.textSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step progress bar ──────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const _StepProgressBar({
    required this.current,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryDefault
                  : (isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final _Role role;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor = isSelected
        ? AppColors.primaryDefault
        : (isDark ? AppColors.darkBorder : AppColors.grayscaleLine);
    final iconBg = isSelected
        ? AppColors.primarySurface
        : (isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton);
    final iconColor = isSelected
        ? AppColors.primaryDefault
        : (isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(role.icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  role.title,
                  style: AppTypography.textSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    role.description,
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Selection indicator (top-right)
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primaryDefault : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDefault
                        : (isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
