import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import 'auth_screen_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // ── Validators ──────────────────────────────────────────────────────────────

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[\w.+-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\-.]+$');
    if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required.';
    if (val.length < 8) return 'Must be at least 8 characters.';
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showError(_friendlyError(e.code));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final credential = await authRepo.signInWithGoogle();
      if (credential == null) return;
      if (!mounted) return;
      final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/role-selection', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError('Google Sign-In failed: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showError('Google Sign-In error: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.errorDark,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        body: Stack(
          children: [
            // ── Dark-mode radial glow ──────────────────────────────────────
            if (isDark)
              Positioned(
                top: -60,
                right: -60,
                child: _GlowCircle(
                  size: 260,
                  color: AppColors.primaryDefault.withValues(alpha: 0.16),
                ),
              ),

            // ── Main content ───────────────────────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, top: 4),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.grayscaleTitleActive,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Logo
                            const Center(child: AppLogoMark(scale: 0.72)),

                            const SizedBox(height: 28),

                            // Title + subtitle
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back!',
                                    style:
                                        AppTypography.displaySmallBold.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.grayscaleTitleActive,
                                      fontSize: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Login to continue your startup journey',
                                    style: AppTypography.textSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.grayscaleBodyText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Form fields
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hintText: 'you@example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                    ),
                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hintText: '••••••••',
                                      isPassword: true,
                                      validator: _validatePassword,
                                    ),
                                    const SizedBox(height: 12),

                                    // Forgot password link
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                            context, '/forgot-password'),
                                        child: Text(
                                          'Forgot password?',
                                          style:
                                              AppTypography.textSmall.copyWith(
                                            color: AppColors.primaryDefault,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // CTAs
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                  24, 24, 24, bottomPadding + 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PrimaryButton(
                                    label: 'Login',
                                    isLoading: _isLoading,
                                    onPressed: _submit,
                                  ),
                                  const SizedBox(height: 20),
                                  const OrDivider(),
                                  const SizedBox(height: 20),
                                  GoogleButton(
                                    isLoading: _isGoogleLoading,
                                    onPressed: _signInWithGoogle,
                                  ),
                                  const SizedBox(height: 24),
                                  AuthSwitchRow(
                                    question: "Don't have an account?",
                                    actionLabel: 'Create Account',
                                    onTap: () => Navigator.pushReplacementNamed(
                                        context, '/signup'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
