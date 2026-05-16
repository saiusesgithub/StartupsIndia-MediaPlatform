import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/style_guide.dart';

// ── Interest data ──────────────────────────────────────────────────────────────

class _Interest {
  final String id;
  final String title;
  final IconData icon;

  const _Interest({
    required this.id,
    required this.title,
    required this.icon,
  });
}

const _interests = [
  _Interest(id: 'ai', title: 'AI', icon: Icons.auto_awesome_rounded),
  _Interest(id: 'saas', title: 'SaaS', icon: Icons.cloud_rounded),
  _Interest(
      id: 'fintech',
      title: 'Fintech',
      icon: Icons.account_balance_wallet_rounded),
  _Interest(id: 'edtech', title: 'Edtech', icon: Icons.cast_for_education_rounded),
  _Interest(
      id: 'creator_economy',
      title: 'Creator Economy',
      icon: Icons.palette_rounded),
  _Interest(
      id: 'ecommerce', title: 'E-commerce', icon: Icons.shopping_bag_rounded),
  _Interest(
      id: 'startup_news', title: 'Startup News', icon: Icons.newspaper_rounded),
  _Interest(
      id: 'investing', title: 'Investing', icon: Icons.show_chart_rounded),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class InterestSelectionScreen extends ConsumerStatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  ConsumerState<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState
    extends ConsumerState<InterestSelectionScreen> {
  final Set<String> _selected = {};
  bool _isLoading = false;

  Future<void> _completeSetup() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // The role was passed as a route argument from RoleSelectionScreen
    final role =
        ModalRoute.of(context)!.settings.arguments as String? ?? '';

    setState(() => _isLoading = true);
    try {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/fill-profile',
        arguments: {
          'role': role,
          'interests': _selected.toList(),
        },
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save preferences. Please try again.'),
          backgroundColor: AppColors.errorDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    // Back button row + progress
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StepProgressBar(
                              current: 2, total: 2, isDark: isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Step 2 of 2',
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
                          const TextSpan(text: 'Choose your '),
                          TextSpan(
                            text: 'interests',
                            style: AppTypography.displaySmallBold.copyWith(
                              color: AppColors.primaryDefault,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select topics you want to follow. Pick as many as you like.',
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

              // ── Interest grid ────────────────────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _interests.map((interest) {
                    final isSelected = _selected.contains(interest.id);
                    return _InterestCard(
                      interest: interest,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selected.remove(interest.id);
                        } else {
                          _selected.add(interest.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ),

              // ── Bottom CTA ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 20),
                child: Column(
                  children: [
                    // Selected count indicator
                    if (_selected.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${_selected.length} interest${_selected.length == 1 ? '' : 's'} selected',
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.primaryDefault,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || _selected.isEmpty
                            ? null
                            : _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDefault,
                          disabledBackgroundColor: AppColors.primaryDefault
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Complete Setup',
                                style: AppTypography.linkMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You can update your interests anytime from your profile.',
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

// ── Step progress bar (shared) ─────────────────────────────────────────────────

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

// ── Interest card ──────────────────────────────────────────────────────────────

class _InterestCard extends StatelessWidget {
  final _Interest interest;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _InterestCard({
    required this.interest,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            // Content — centered
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(interest.icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    interest.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.primaryDefault : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDefault
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.grayscaleLine),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 12, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
