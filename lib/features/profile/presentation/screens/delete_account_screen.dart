import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../../../../theme/style_guide.dart';

const _dangerRed = Color(0xFFEF4444);

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    final providers = FirebaseAuth.instance.currentUser?.providerData ?? [];
    _isGoogleUser = providers.any((p) => p.providerId == 'google.com') &&
        !providers.any((p) => p.providerId == 'password');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: _isGoogleUser
                        ? _buildGoogleFlow(isDark)
                        : _buildPasswordFlow(isDark),
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(
                    child: CircularProgressIndicator(color: _dangerRed),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              'Delete Account',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildWarningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dangerRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is permanent',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dangerRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your profile, bookmarks, community memberships, and all activity will be permanently deleted and cannot be recovered.',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 12,
                    height: 1.5,
                    color: _dangerRed.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFlow(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWarningCard(isDark),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirm with your password',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your current password',
                  isPassword: true,
                  validator: (v) =>
                      (v ?? '').isEmpty ? 'Password is required' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _DeleteButton(
            isSubmitting: _isSubmitting,
            onTap: _deleteWithPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleFlow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWarningCard(isDark),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Text(
            'Your account uses Google Sign-In. Tap the button below to re-authenticate and permanently delete your account.',
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              height: 1.55,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _DeleteButton(
          isSubmitting: _isSubmitting,
          onTap: _deleteWithGoogle,
        ),
      ],
    );
  }

  Future<void> _deleteWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await _eraseAndDelete(user);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'wrong-password'
          ? 'Incorrect password. Please try again.'
          : 'Authentication failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteWithGoogle() async {
    setState(() => _isSubmitting = true);

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final auth = googleUser.authentication;
      final credential =
          GoogleAuthProvider.credential(idToken: auth.idToken);
      final user = FirebaseAuth.instance.currentUser!;
      await user.reauthenticateWithCredential(credential);
      await _eraseAndDelete(user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _eraseAndDelete(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .delete();
    await user.delete();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

class _DeleteButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onTap;

  const _DeleteButton({required this.isSubmitting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSubmitting
              ? _dangerRed.withValues(alpha: 0.5)
              : _dangerRed,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                'Permanently Delete Account',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
