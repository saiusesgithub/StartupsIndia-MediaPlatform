import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/app_error_reporter.dart';
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
  final Map<String, TextEditingController> _roleControllers = {};

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    final email = user?.email ?? '';
    _emailController.text = email;
    _fullNameController.text = user?.displayName ?? '';
    _usernameController.text = email.contains('@')
        ? email.split('@').first
        : '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    for (final controller in _roleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _roleController(String key) {
    return _roleControllers.putIfAbsent(key, TextEditingController.new);
  }

  Map<String, Object?> _setupArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map ? Map<String, Object?>.from(args) : const {};
  }

  Map<String, dynamic> _collectRoleDetails(String role) {
    final details = <String, dynamic>{};
    for (final field in _roleFieldsFor(role)) {
      final value = _roleController(field.key).text.trim();
      if (value.isNotEmpty) details[field.key] = value;
    }
    return details;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        setState(() => _isSubmitting = false);
        return;
      }

      final args = ModalRoute.of(context)?.settings.arguments;
      final setup = args is Map ? args : const <String, Object?>{};
      final role = setup['role'] as String? ?? '';
      final interests = List<String>.from(setup['interests'] as List? ?? []);
      final username = _usernameController.text.trim();
      final firestoreRepo = ref.read(firestoreRepositoryProvider);
      final available = await firestoreRepo.isUsernameAvailable(
        username,
        currentUser.uid,
      );
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      String avatarUrl = currentUser.photoURL ?? '';
      if (_pickedImage != null) {
        avatarUrl = await firestoreRepo.uploadImage(_pickedImage!.path);
      }

      final updatedUser = UserModel(
        uid: currentUser.uid,
        username: username,
        fullName: _fullNameController.text.trim(),
        email: currentUser.email ?? _emailController.text.trim(),
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
        roleDetails: _collectRoleDetails(role),
        onboardingCompleted: true,
      );

      await authRepo.updateUserData(updatedUser);

      // Best-effort: follow selected topics. Failure here doesn't block onboarding.
      for (final interest in interests) {
        try {
          await firestoreRepo.followTopic(currentUser.uid, interest);
        } catch (error, stackTrace) {
          AppErrorReporter.record(
            error,
            stackTrace,
            reason: 'Failed to follow onboarding topic',
          );
          // Ignore — user can re-follow topics from settings later.
        }
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final setup = _setupArgs();
    final role = setup['role'] as String? ?? '';

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.grayscaleSecondaryButton,
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
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Full name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _usernameController,
                                label: 'Username',
                                hintText: 'yourhandle',
                                validator: (val) {
                                  final text = val?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Username is required';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9_]{3,24}$',
                                  ).hasMatch(text)) {
                                    return 'Use 3-24 letters, numbers or _';
                                  }
                                  return null;
                                },
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
                                keyboardType: TextInputType.emailAddress,
                                readOnly: true,
                                validator: (val) {
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
                          _RoleDetailsSection(
                            role: role,
                            isDark: isDark,
                            controllerFor: _roleController,
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
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.grayscaleWhite;
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
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).maybePop(),
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
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : null,
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
      color: isDark
          ? AppColors.darkBackground
          : AppColors.grayscaleSecondaryButton,
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

class _RoleField {
  final String key;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _RoleField({
    required this.key,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });
}

List<_RoleField> _roleFieldsFor(String role) {
  return switch (role) {
    'student' => const [
      _RoleField(
        key: 'collegeName',
        label: 'College Name',
        hint: 'Your college',
      ),
      _RoleField(
        key: 'degreeCourse',
        label: 'Degree / Course',
        hint: 'B.Tech, BBA, MBA',
      ),
      _RoleField(key: 'year', label: 'Year', hint: '1st, 2nd, 3rd, Final'),
      _RoleField(
        key: 'branch',
        label: 'Branch / Specialization',
        hint: 'Computer Science',
      ),
      _RoleField(key: 'skills', label: 'Skills', hint: 'Design, Flutter, AI'),
      _RoleField(
        key: 'lookingFor',
        label: 'Looking For',
        hint: 'Internship, co-founder, learning',
      ),
    ],
    'founder' => const [
      _RoleField(
        key: 'startupName',
        label: 'Startup Name',
        hint: 'Your startup',
      ),
      _RoleField(
        key: 'startupStage',
        label: 'Startup Stage',
        hint: 'Idea, MVP, Revenue, Scaling',
      ),
      _RoleField(key: 'industry', label: 'Industry', hint: 'Fintech, SaaS, AI'),
      _RoleField(
        key: 'startupDescription',
        label: 'Startup Description',
        hint: 'What are you building?',
      ),
      _RoleField(
        key: 'businessNeeds',
        label: 'Looking For',
        hint: 'Funding, mentors, hiring',
      ),
      _RoleField(
        key: 'startupLocation',
        label: 'Startup Location',
        hint: 'City / State',
      ),
      _RoleField(
        key: 'teamSize',
        label: 'Team Size',
        hint: '5',
        keyboardType: TextInputType.number,
      ),
    ],
    'mentor' => const [
      _RoleField(
        key: 'profession',
        label: 'Profession / Designation',
        hint: 'Product Leader',
      ),
      _RoleField(
        key: 'company',
        label: 'Company / Organization',
        hint: 'Company name',
      ),
      _RoleField(
        key: 'expertise',
        label: 'Expertise',
        hint: 'Product, GTM, fundraising',
      ),
      _RoleField(
        key: 'yearsExperience',
        label: 'Years of Experience',
        hint: '10',
        keyboardType: TextInputType.number,
      ),
      _RoleField(key: 'industry', label: 'Industry', hint: 'SaaS, fintech'),
      _RoleField(
        key: 'mentorshipArea',
        label: 'Mentorship Area',
        hint: 'Startup, marketing, finance',
      ),
      _RoleField(
        key: 'availability',
        label: 'Availability',
        hint: 'Free, paid, group session',
      ),
    ],
    'investor' => const [
      _RoleField(
        key: 'investorType',
        label: 'Investor Type',
        hint: 'Angel, VC, family office',
      ),
      _RoleField(key: 'firmName', label: 'Firm Name', hint: 'Firm / fund name'),
      _RoleField(
        key: 'investmentRange',
        label: 'Investment Range',
        hint: '10L - 1Cr',
      ),
      _RoleField(
        key: 'preferredIndustries',
        label: 'Preferred Industries',
        hint: 'AI, SaaS, consumer',
      ),
      _RoleField(
        key: 'preferredStage',
        label: 'Preferred Startup Stage',
        hint: 'Idea, MVP, revenue',
      ),
      _RoleField(
        key: 'portfolioCompanies',
        label: 'Portfolio Companies',
        hint: 'Optional',
      ),
    ],
    'college' => const [
      _RoleField(
        key: 'collegeName',
        label: 'College Name',
        hint: 'College / institute',
      ),
      _RoleField(
        key: 'collegeType',
        label: 'College Type',
        hint: 'Engineering, MBA, university',
      ),
      _RoleField(
        key: 'cityState',
        label: 'City / State',
        hint: 'Bengaluru, Karnataka',
      ),
      _RoleField(
        key: 'contactPersonName',
        label: 'Contact Person Name',
        hint: 'Full name',
      ),
      _RoleField(
        key: 'designation',
        label: 'Designation',
        hint: 'Placement officer',
      ),
      _RoleField(
        key: 'numberOfStudents',
        label: 'Number of Students',
        hint: '1200',
        keyboardType: TextInputType.number,
      ),
      _RoleField(
        key: 'interestedIn',
        label: 'Interested In',
        hint: 'Programs, incubation, events',
      ),
    ],
    _ => const [
      _RoleField(
        key: 'interestArea',
        label: 'Startup Interest Area',
        hint: 'AI, funding, product, community',
      ),
      _RoleField(
        key: 'lookingFor',
        label: 'Looking For',
        hint: 'Learning, networking, events',
      ),
    ],
  };
}

class _RoleDetailsSection extends StatelessWidget {
  final String role;
  final bool isDark;
  final TextEditingController Function(String key) controllerFor;

  const _RoleDetailsSection({
    required this.role,
    required this.isDark,
    required this.controllerFor,
  });

  @override
  Widget build(BuildContext context) {
    final fields = _roleFieldsFor(role);
    if (fields.isEmpty) return const SizedBox.shrink();

    return _FormSection(
      label: role.isEmpty
          ? 'Role Details'
          : '${role.replaceAll('_', ' ')} Details',
      isDark: isDark,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          AppTextField(
            controller: controllerFor(fields[i].key),
            label: fields[i].label,
            hintText: fields[i].hint,
            keyboardType: fields[i].keyboardType,
          ),
          if (i != fields.length - 1) const SizedBox(height: 14),
        ],
      ],
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
        ? AppColors.darkTextSecondary.withValues(alpha: 0.55)
        : AppColors.grayscaleButtonText.withValues(alpha: 0.62);
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
