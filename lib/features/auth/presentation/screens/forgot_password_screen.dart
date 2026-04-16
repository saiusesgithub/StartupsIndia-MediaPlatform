import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

/// Forgot Password screen — step 1: enter email
/// Detects whether the account uses Google SSO and shows the right guidance.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _ScreenState { input, loading, success, googleAccount }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  _ScreenState _state = _ScreenState.input;
  String? _errorMessage;

  // ── Validator ────────────────────────────────────────────────────────────

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[\w.+-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\-.]+$');
    if (!emailRegex.hasMatch(val.trim())) return 'Enter a valid email address.';
    return null;
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _state = _ScreenState.loading;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final authRepo = ref.read(authRepositoryProvider);

    try {
      // Send the reset email directly. If the user only has a Google account, 
      // Firebase will still send a password reset email to allow them to add
      // a password provider to their account, or it will succeed silently/fail
      // based on Firebase project settings.
      await authRepo.sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() => _state = _ScreenState.success);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.input;
        _errorMessage = _friendlyError(e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.input;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      appBar: AppBar(
        backgroundColor: AppColors.grayscaleWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.grayscaleTitleActive, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (_state) {
            _ScreenState.loading => const _LoadingView(),
            _ScreenState.success =>
              _SuccessView(email: _emailController.text.trim()),
            _ScreenState.googleAccount =>
              _GoogleAccountView(email: _emailController.text.trim()),
            _ => _InputView(
                key: const ValueKey('input'),
                formKey: _formKey,
                emailController: _emailController,
                validateEmail: _validateEmail,
                onSubmit: _submit,
                errorMessage: _errorMessage,
              ),
          },
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Input View  (step 1 — enter email)
// ────────────────────────────────────────────────────────────────────────────

class _InputView extends StatelessWidget {
  const _InputView({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.validateEmail,
    required this.onSubmit,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final FormFieldValidator<String> validateEmail;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // ── Illustration ─────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDefault.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 52,
                        color: AppColors.primaryDefault,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // ── Heading ──────────────────────────────────────────────
                  Text(
                    'Forgot\nPassword?',
                    style: AppTypography.displayLargeBold.copyWith(
                      color: AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email and we\'ll send\nyou a secure link to reset your password.',
                    style: AppTypography.textLarge.copyWith(
                      color: AppColors.grayscaleBodyText,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // ── Email field ──────────────────────────────────────────
                  AppTextField(
                    controller: emailController,
                    label: 'Email*',
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  // ── Error banner ─────────────────────────────────────────
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorDark.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.errorDark.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.errorDark, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: AppTypography.textSmall.copyWith(
                                color: AppColors.errorDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // ── CTA bottom ───────────────────────────────────────────────────
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.grayscaleWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Send Reset Link',
                style: AppTypography.linkMedium.copyWith(
                  color: AppColors.grayscaleWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Loading View
// ────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryDefault),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Success View  (email sent)
// ────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 58,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Check Your Email',
            style: AppTypography.displaySmallBold.copyWith(
              color: AppColors.grayscaleTitleActive,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.textLarge.copyWith(
                color: AppColors.grayscaleBodyText,
              ),
              children: [
                const TextSpan(text: 'We\'ve sent a password reset link to\n'),
                TextSpan(
                  text: email,
                  style: AppTypography.textLarge.copyWith(
                    color: AppColors.primaryDefault,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                    text: '\n\nClick the link in the email to reset\nyour password.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Didn\'t receive it? Check your spam folder.',
            style: AppTypography.textSmall.copyWith(
              color: AppColors.grayscaleBodyText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Back to Login',
                style: AppTypography.linkMedium.copyWith(
                  color: AppColors.grayscaleWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Google Account View  (account is Google-only, no password to reset)
// ────────────────────────────────────────────────────────────────────────────

class _GoogleAccountView extends StatelessWidget {
  const _GoogleAccountView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              size: 60,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Google Account\nDetected',
            style: AppTypography.displaySmallBold.copyWith(
              color: AppColors.grayscaleTitleActive,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.textLarge.copyWith(
                color: AppColors.grayscaleBodyText,
              ),
              children: [
                TextSpan(
                  text: email,
                  style: AppTypography.textLarge.copyWith(
                    color: AppColors.primaryDefault,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text:
                      ' is signed in with Google.\n\nYou don\'t have a password to reset. '
                      'Use the "Continue with Google" button on the login screen instead.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Back to Login',
                style: AppTypography.linkMedium.copyWith(
                  color: AppColors.grayscaleWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Try a different email',
              style: AppTypography.linkMedium.copyWith(
                color: AppColors.grayscaleBodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
