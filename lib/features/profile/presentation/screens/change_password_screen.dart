import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../../../../theme/style_guide.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

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
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: _isGoogleUser
                        ? _buildGoogleUserMessage(isDark)
                        : _buildPasswordForm(isDark),
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryDefault),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon:
                Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          ),
          Expanded(
            child: Text(
              'Change Password',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildGoogleUserMessage(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: Color(0xFF5C6BC0), size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'Signed in with Google',
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your account uses Google Sign-In, so there\'s no password to change. Manage your password through your Google account.',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 14,
                height: 1.55,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoCard(isDark: isDark),
          const SizedBox(height: 20),
          _FormSection(
            label: 'Current Password',
            isDark: isDark,
            children: [
              AppTextField(
                controller: _currentController,
                label: 'Current Password',
                hintText: 'Enter your current password',
                isPassword: true,
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Current password is required' : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _FormSection(
            label: 'New Password',
            isDark: isDark,
            children: [
              AppTextField(
                controller: _newController,
                label: 'New Password',
                hintText: 'At least 8 characters',
                isPassword: true,
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'New password is required';
                  if (v!.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmController,
                label: 'Confirm New Password',
                hintText: 'Repeat new password',
                isPassword: true,
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'Please confirm your password';
                  if (v != _newController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SubmitButton(
            label: 'Update Password',
            isSubmitting: _isSubmitting,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final email = user.email!;

      // Re-authenticate with current password first
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'wrong-password'
          ? 'Current password is incorrect.'
          : e.code == 'requires-recent-login'
              ? 'Please log out and log back in before changing your password.'
              : 'Failed to update password. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool isDark;
  const _InfoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryDefault.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primaryDefault, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Choose a strong password with letters, numbers, and symbols.',
              style: AppTypography.textSmall.copyWith(
                fontSize: 12,
                color: AppColors.primaryDefault,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String label;
  final bool isDark;
  final List<Widget> children;

  const _FormSection({
    required this.label,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.textSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.label,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isSubmitting
              ? AppColors.primaryDefault.withValues(alpha: 0.5)
              : AppColors.primaryDefault,
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
                label,
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
