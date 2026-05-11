import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  bool _rememberMe = true;
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

  // ── Submit ──────────────────────────────────────────────────────────────────
  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
        Navigator.pushNamedAndRemoveUntil(context, '/select-country', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
      case 'user-not-found':    return 'No account found for this email.';
      case 'wrong-password':    return 'Incorrect password. Please try again.';
      case 'invalid-email':     return 'Please enter a valid email address.';
      case 'user-disabled':     return 'This account has been disabled.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default:                  return 'Login failed. Please try again.';
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
      body: Column(
        children: [
          // ── 1. Brand header (fixed) ────────────────────────────────────
          BrandHeader(
            title: 'Welcome Back',
            subtitle: 'Sign in to continue reading',
          ),

          // ── 2. Scrollable form fields ──────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const SizedBox(height: 10),
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
                                onChanged: (val) =>
                                    setState(() => _rememberMe = val ?? true),
                                activeColor: AppColors.primaryDefault,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                side: const BorderSide(
                                    color: AppColors.grayscaleLine),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: AppTypography.textSmall.copyWith(
                                color: AppColors.grayscaleBodyText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, '/forgot-password'),
                          child: Text(
                            'Forgot password?',
                            style: AppTypography.textSmall.copyWith(
                              color: AppColors.primaryDefault,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Pinned bottom CTAs ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              24, 16, 24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  label: 'Login',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                OrDivider(),
                const SizedBox(height: 16),
                GoogleButton(
                  isLoading: _isGoogleLoading,
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: 20),
                AuthSwitchRow(
                  question: "Don't have an account?",
                  actionLabel: 'Sign Up',
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/signup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
