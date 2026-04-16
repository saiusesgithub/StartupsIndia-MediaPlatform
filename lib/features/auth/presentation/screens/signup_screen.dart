import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // ── Validators ─────────────────────────────────────────────────────────────

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[\w.+-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\-.]+$');
    if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address.';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required.';
    if (val.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain at least one uppercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain at least one number.';
    if (!RegExp(r'[@#\$%^&*!?]').hasMatch(val)) return 'Must contain at least one special character (@#\$%^&*!?).';
    return null;
  }

  // ── Email / Password Submit ────────────────────────────────────────────────

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;
        // New account → start full onboarding flow
        Navigator.pushNamed(context, '/select-country');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.code)),
            backgroundColor: AppColors.errorDark,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  void _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final credential = await authRepo.signInWithGoogle();

      if (credential == null) return; // user cancelled

      if (!mounted) return;

      // New user → go through onboarding; returning user → go home
      final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        Navigator.pushNamedAndRemoveUntil(context, '/select-country', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.message}'),
          backgroundColor: AppColors.errorDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In error: $e'),
          backgroundColor: AppColors.errorDark,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':  return 'An account already exists for this email.';
      case 'invalid-email':         return 'Please enter a valid email address.';
      case 'weak-password':         return 'Password should be at least 6 characters.';
      case 'operation-not-allowed': return 'Email/password sign-up is not enabled.';
      default:                      return 'Sign up failed. Please try again.';
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
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hello!',
                    style: AppTypography.displayLargeBold.copyWith(
                      color: AppColors.primaryDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signup to get Started',
                    style: AppTypography.textLarge.copyWith(
                      color: AppColors.grayscaleBodyText,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Email field ──────────────────────────────────────────
                  AppTextField(
                    controller: _emailController,
                    label: 'Email*',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ───────────────────────────────────────
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password*',
                    isPassword: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? true);
                              },
                              activeColor: AppColors.primaryDefault,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              side: const BorderSide(color: AppColors.grayscaleBodyText),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: AppTypography.textSmall.copyWith(
                              color: AppColors.grayscaleBodyText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDefault,
                      disabledBackgroundColor: AppColors.primaryDefault,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.grayscaleWhite,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: AppTypography.linkMedium.copyWith(
                              color: AppColors.grayscaleWhite,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.grayscaleLine)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleBodyText,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.grayscaleLine)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google Sign-In
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.grayscaleSecondaryButton,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const FaIcon(FontAwesomeIcons.google,
                              color: AppColors.grayscaleTitleActive, size: 20),
                      label: Text(
                        'Continue with Google',
                        style: AppTypography.linkMedium.copyWith(
                          color: AppColors.grayscaleButtonText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account ? ',
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleBodyText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'Login',
                          style: AppTypography.linkMedium.copyWith(
                            color: AppColors.primaryDefault,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
