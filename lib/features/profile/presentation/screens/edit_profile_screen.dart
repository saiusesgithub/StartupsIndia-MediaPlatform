import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../../../../theme/style_guide.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Uint8List? _pickedAvatarBytes;
  String? _pickedAvatarPath;
  UserModel? _currentUser;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          _buildAvatarEditor(isDark),
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
                                label: 'Email Address',
                                hintText: 'example@email.com',
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hintText: '+91 98765 43210',
                                validator: _validatePhone,
                                keyboardType: TextInputType.phone,
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
                          const SizedBox(height: 28),
                          _SaveButton(
                            isSubmitting: _isSubmitting,
                            onTap: _submit,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;

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
            onPressed: _isSubmitting ? null : () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close_rounded, color: textColor, size: 22),
          ),
          Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          // Save pill button
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _isSubmitting
                    ? AppColors.primaryDefault.withValues(alpha: 0.5)
                    : AppColors.primaryDefault,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Save',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────

  Widget _buildAvatarEditor(bool isDark) {
    final currentAvatar = _currentUser?.avatarUrl ?? '';

    return Center(
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
                  : AppColors.grayscaleSecondaryButton,
              backgroundImage: _pickedAvatarBytes != null
                  ? MemoryImage(_pickedAvatarBytes!)
                  : null,
              child: _pickedAvatarBytes == null
                  ? ClipOval(
                      child: currentAvatar.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: currentAvatar,
                              width: 108,
                              height: 108,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  _avatarFallback(isDark),
                            )
                          : _avatarFallback(isDark),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: GestureDetector(
                onTap: _isSubmitting ? null : _pickAvatar,
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
                    Icons.camera_alt_outlined,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Business logic ─────────────────────────────────────────────────────────

  Future<void> _loadCurrentUser() async {
    final authRepo = ref.read(authRepositoryProvider);
    final user = await authRepo.getCurrentUserModel();
    if (!mounted) return;

    final UserModel resolved =
        user ??
        const UserModel(
          uid: 'demo_user',
          username: 'wilsonfranci',
          fullName: 'Wilson Franci',
          email: 'wilson@example.com',
          phone: '+91 98765 43210',
          displayName: 'Wilson Franci',
          bio: 'Building the future of Indian startups.',
          avatarUrl: '',
          websiteUrl: 'https://example.com',
          followersCount: 0,
          followingCount: 0,
          newsCount: 0,
        );

    setState(() {
      _currentUser = resolved;
      _usernameController.text = resolved.username;
      _fullNameController.text =
          resolved.fullName.isEmpty ? resolved.displayName : resolved.fullName;
      _emailController.text = resolved.email;
      _phoneController.text = resolved.phone;
      _bioController.text = resolved.bio;
      _websiteController.text = resolved.websiteUrl;
    });
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1080,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedAvatarPath = image.path;
      _pickedAvatarBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final baseUser =
        _currentUser ??
        const UserModel(
          uid: 'demo_user',
          displayName: 'User',
          bio: '',
          avatarUrl: '',
          websiteUrl: '',
          followersCount: 0,
          followingCount: 0,
          newsCount: 0,
        );

    try {
      String avatarUrl = baseUser.avatarUrl;
      if (_pickedAvatarPath != null) {
        avatarUrl = await ref
            .read(firestoreRepositoryProvider)
            .uploadImage(_pickedAvatarPath!);
      }

      final updatedUser = baseUser.copyWith(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        displayName: _fullNameController.text.trim().isEmpty
            ? baseUser.displayName
            : _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        avatarUrl: avatarUrl,
      );

      await ref.read(authRepositoryProvider).updateUserData(updatedUser);
      if (!mounted) return;

      _currentUser = updatedUser;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed. Please try again.')),
      );
    }
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[\+\d\-\s]{7,18}$');
    if (!phoneRegex.hasMatch(text)) return 'Enter a valid phone number';
    return null;
  }

  Widget _avatarFallback(bool isDark) {
    return Container(
      width: 108,
      height: 108,
      color: isDark ? AppColors.darkSurface : AppColors.grayscaleSecondaryButton,
      child: Icon(
        Icons.person_rounded,
        size: 52,
        color: isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText,
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

class _SaveButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onTap;
  final bool isDark;

  const _SaveButton({
    required this.isSubmitting,
    required this.onTap,
    required this.isDark,
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
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Save Changes',
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
