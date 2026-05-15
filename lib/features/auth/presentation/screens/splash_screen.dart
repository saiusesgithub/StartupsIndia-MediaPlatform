import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/style_guide.dart';
import 'auth_screen_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.50, 1.0, curve: Curves.easeIn),
    );

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 2700), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    // Check whether the user has completed onboarding.
    // Falls back to /home on any error so authenticated users are never stuck.
    String destination = '/home';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final done = doc.data()?['onboardingCompleted'] as bool? ?? false;
      if (!done) destination = '/role-selection';
    } catch (_) {
      destination = '/home';
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background glows (dark mode) ──────────────────────────────
            if (isDark) ...[
              Positioned(
                top: -80,
                right: -80,
                child: _GlowCircle(
                  size: 300,
                  color: AppColors.primaryDefault.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: _GlowCircle(
                  size: 240,
                  color: AppColors.primaryDefault.withValues(alpha: 0.12),
                ),
              ),
            ],

            // ── Logo + tagline ─────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _entryController,
                    builder: (_, child) => FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(scale: _logoScale, child: child),
                    ),
                    child: const AppLogoMark(),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'The Startup Ecosystem',
                      style: AppTypography.textSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                        fontSize: 13,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Loading indicator ──────────────────────────────────────────
            const Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: Center(child: _PulsingDots()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radial glow decoration ─────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

// ── Three staggered pulsing dots ───────────────────────────────────────────────

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animations = List.generate(3, _buildDotAnimation);
  }

  Animation<double> _buildDotAnimation(int index) {
    final start = index * 0.2;
    final end = (start + 0.4).clamp(0.0, 1.0);
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.20, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.20)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Interval(start, end)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final anim = _animations[i];
        return AnimatedBuilder(
          animation: anim,
          builder: (_, _) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: anim.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
