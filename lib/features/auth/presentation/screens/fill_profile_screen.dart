import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../auth/domain/models/user_model.dart';
import '../providers/auth_providers.dart';

class FillProfileScreen extends ConsumerStatefulWidget {
  const FillProfileScreen({super.key});

  @override
  ConsumerState<FillProfileScreen> createState() => _FillProfileScreenState();
}

class _FillProfileScreenState extends ConsumerState<FillProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    _emailController.text = email;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final currentUser = authRepo.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final args = ModalRoute.of(context)?.settings.arguments;
      final setup = args is Map ? args : const <String, Object?>{};
      final role = setup['role'] as String? ?? '';
      final interests = List<String>.from(setup['interests'] as List? ?? []);

      String avatarUrl = currentUser.photoURL ?? '';
      final firestoreRepo = ref.read(firestoreRepositoryProvider);
      if (_pickedImage != null) {
        avatarUrl = await firestoreRepo.uploadImage(_pickedImage!.path);
      }

      final updatedUser = UserModel(
        uid: currentUser.uid,
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        displayName: _fullNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? 'Building the future of Indian startups.'
            : _bioController.text.trim(),
        avatarUrl: avatarUrl,
        websiteUrl: _websiteController.text.trim(),
        followersCount: 0,
        followingCount: 0,
        newsCount: 0,
        role: role,
        interests: interests,
        onboardingCompleted: true,
      );

      await authRepo.updateUserData(updatedUser);
      for (final interest in interests) {
        await firestoreRepo.followTopic(currentUser.uid, interest);
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _buildAvatarPicker(isDark),
                          const SizedBox(height: 28),
                          _FormSection(
                            label: 'Identity',
                            isDark: isDark,
                            children: [
                              AppTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                hintText: 'Your full name',
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _usernameController,
                                label: 'Username',
                                hintText: 'yourhandle',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _FormSection(
                            label: 'Contact',
                            isDark: isDark,
                            children: [
                              AppTextField(
                                controller: _emailController,
                                label: 'Email Address*',
                                hintText: 'example@email.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  final ok = RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(val.trim());
                                  if (!ok) return 'Enter a valid email address';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _phoneController,
                                label: 'Phone Number*',
                                hintText: '+91 98765 43210',
                                keyboardType: TextInputType.phone,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Phone number is required';
                                  }
                                  final ok = RegExp(
                                    r'^[\+\d\-\s]{7,15}$',
                                  ).hasMatch(val.trim());
                                  if (!ok) return 'Enter a valid phone number';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _FormSection(
                            label: 'About',
                            isDark: isDark,
                            children: [
                              _MultilineField(
                                controller: _bioController,
                                label: 'Bio',
                                hintText: 'Tell people what you are building',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _websiteController,
                                label: 'Website',
                                hintText: 'https://yourstartup.com',
                                keyboardType: TextInputType.url,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildContinueButton(isDark),
              ],
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDefault,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

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
            onPressed:
                _isSubmitting ? null : () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 22),
          ),
          Expanded(
            child: Text(
              'Fill Your Profile',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          // Invisible spacer to keep title centered
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Avatar ──────────────────────────────────────────────────────────────────

  Widget _buildAvatarPicker(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _isSubmitting ? null : _pickImage,
        child: SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: isDark
                    ? AppColors.darkSurface
                    : const Color(0xFFEEF1F4),
                backgroundImage:
                    _pickedImage != null ? FileImage(_pickedImage!) : null,
                child: _pickedImage == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFFBDBDBD),
                      )
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDefault,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.grayscaleWhite,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Continue button ─────────────────────────────────────────────────────────

  Widget _buildContinueButton(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submit,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _isSubmitting
                ? AppColors.primaryDefault.withValues(alpha: 0.5)
                : AppColors.primaryDefault,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Continue',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

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
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
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

class _MultilineField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool isDark;

  const _MultilineField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.isDark,
  });

  @override
  State<_MultilineField> createState() => _MultilineFieldState();
}

class _MultilineFieldState extends State<_MultilineField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused
        ? AppColors.primaryDefault
        : (widget.isDark ? AppColors.darkBorder : AppColors.grayscaleLine);
    final fillColor = widget.isDark
        ? AppColors.darkInputBackground
        : AppColors.grayscaleWhite;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;
    final hintColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.grayscaleButtonText;
    final labelColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.grayscaleBodyText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.textSmall.copyWith(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: 4,
            minLines: 3,
            style: AppTypography.textSmall.copyWith(
              color: textColor,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.textSmall.copyWith(
                color: hintColor,
                fontSize: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
