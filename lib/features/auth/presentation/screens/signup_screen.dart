import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // ── Submit ──────────────────────────────────────────────────────────────────
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
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        Navigator.pushNamed(context, '/select-country');
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
      case 'email-already-in-use':  return 'An account already exists for this email.';
      case 'invalid-email':         return 'Please enter a valid email address.';
      case 'weak-password':         return 'Password is too weak.';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // ── 1. Brand header (fixed) ────────────────────────────────────
                    BrandHeader(
                      title: 'Create Account',
                      subtitle: 'Join the StartupsIndia community',
                    ),

                    // ── 2. Scrollable form fields ──────────────────────────────────
                    Padding(
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
                              hintText: 'Min 8 chars, 1 upper, 1 number, 1 symbol',
                              isPassword: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 12),
                            _PasswordHintRow(),
                            const SizedBox(height: 14),
                            // Terms & Conditions
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _agreedToTerms = !_agreedToTerms),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: (val) => setState(
                                          () => _agreedToTerms = val ?? false),
                                      activeColor: AppColors.primaryDefault,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4)),
                                      side: const BorderSide(
                                          color: AppColors.grayscaleLine),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.textSmall.copyWith(
                                          color: AppColors.grayscaleBodyText,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          const TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: AppTypography.textSmall.copyWith(
                                              color: AppColors.primaryDefault,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: AppTypography.textSmall.copyWith(
                                              color: AppColors.primaryDefault,
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

                    // Spacer pushes the CTAs to the bottom when there is space
                    const Spacer(),

                    // ── 3. Pinned bottom CTAs ──────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24, 24, 24,
                        MediaQuery.of(context).padding.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PrimaryButton(
                            label: 'Create Account',
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
                            question: 'Already have an account?',
                            actionLabel: 'Login',
                            onTap: () =>
                                Navigator.pushReplacementNamed(context, '/login'),
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
    );
  }

}

// ── Password hint row ──────────────────────────────────────────────────────────
class _PasswordHintRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: const [
        _HintChip('8+ chars'),
        _HintChip('Uppercase'),
        _HintChip('Number'),
        _HintChip('Symbol'),
      ],
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  const _HintChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.grayscaleSecondaryButton,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.textSmall.copyWith(
          fontSize: 11,
          color: AppColors.grayscaleBodyText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
