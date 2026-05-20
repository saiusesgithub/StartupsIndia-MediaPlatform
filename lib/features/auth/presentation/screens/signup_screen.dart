import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_service_provider.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import 'auth_screen_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
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
    if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain an uppercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain a number.';
    if (!RegExp(r'[@#\$%^&*!?]').hasMatch(val)) return 'Must contain a special character.';
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Please confirm your password.';
    if (val != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _submit() async {
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms & Conditions to continue.');
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, '/role-selection', (_) => false);
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
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                left: -60,
                child: _GlowCircle(
                  size: 260,
                  color: AppColors.primaryDefault.withValues(alpha: 0.14),
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
                                    'Create Account',
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
                                    'Join the StartupsIndia community',
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
                                      hintText: 'Min 8 chars, 1 upper, 1 number, 1 symbol',
                                      isPassword: true,
                                      validator: _validatePassword,
                                    ),
                                    const SizedBox(height: 10),

                                    // Password requirement chips
                                    _PasswordRequirements(isDark: isDark),

                                    const SizedBox(height: 16),
                                    AppTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      hintText: 'Re-enter your password',
                                      isPassword: true,
                                      validator: _validateConfirmPassword,
                                    ),
                                    const SizedBox(height: 18),
                                    _ThemePreferenceCard(isDark: isDark),
                                    const SizedBox(height: 20),

                                    // Terms & Conditions
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _agreedToTerms = !_agreedToTerms),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: _agreedToTerms,
                                              onChanged: (val) => setState(() =>
                                                  _agreedToTerms = val ?? false),
                                              activeColor:
                                                  AppColors.primaryDefault,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              side: BorderSide(
                                                color: isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.grayscaleLine,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: AppTypography.textSmall
                                                    .copyWith(
                                                  color: isDark
                                                      ? AppColors.darkTextSecondary
                                                      : AppColors
                                                          .grayscaleBodyText,
                                                  fontSize: 13,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                      text: 'I agree to the '),
                                                  TextSpan(
                                                    text: 'Terms of Service',
                                                    style: AppTypography
                                                        .textSmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .primaryDefault,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const TextSpan(text: ' and '),
                                                  TextSpan(
                                                    text: 'Privacy Policy',
                                                    style: AppTypography
                                                        .textSmall
                                                        .copyWith(
                                                      color: AppColors
                                                          .primaryDefault,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
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
                                    label: 'Create Account',
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
                                    question: 'Already have an account?',
                                    actionLabel: 'Login',
                                    onTap: () => Navigator.pushReplacementNamed(
                                        context, '/login'),
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

// ── Password requirement chips ─────────────────────────────────────────────────

class _PasswordRequirements extends StatelessWidget {
  final bool isDark;
  const _PasswordRequirements({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: const [
        _ReqChip('8+ chars'),
        _ReqChip('Uppercase'),
        _ReqChip('Number'),
        _ReqChip('Symbol'),
      ],
    );
  }
}

class _ReqChip extends StatelessWidget {
  final String label;
  const _ReqChip(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleSecondaryButton,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.textSmall.copyWith(
          fontSize: 11,
          color: isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Radial glow decoration ─────────────────────────────────────────────────────

class _ThemePreferenceCard extends ConsumerWidget {
  final bool isDark;

  const _ThemePreferenceCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeServiceProvider) == ThemeMode.dark;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.grayscaleSecondaryButton;
    final border = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final title =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.primaryDefault,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App appearance',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDarkMode ? 'Dark mode selected' : 'Light mode selected',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDarkMode,
            activeThumbColor: AppColors.primaryDefault,
            onChanged: (value) =>
                ref.read(themeServiceProvider.notifier).setDarkMode(value),
          ),
        ],
      ),
    );
  }
}

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
