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
import '../../../../core/utils/app_error_reporter.dart';

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
  final _locationController = TextEditingController();
  final _roleDetailControllers = <String, TextEditingController>{};

  final ImagePicker _picker = ImagePicker();

  Uint8List? _pickedAvatarBytes;
  String? _pickedAvatarPath;
  UserModel? _currentUser;
  bool _isSubmitting = false;

  // Field definitions per role: (key, label, hint)
  static const _roleFields = <String, List<(String, String, String)>>{
    'student': [
      ('collegeName', 'College Name', 'e.g. IIT Bombay'),
      ('degreeCourse', 'Degree / Course', 'e.g. B.Tech Computer Science'),
      ('year', 'Year', 'e.g. 2nd Year'),
      ('branch', 'Branch / Specialization', 'e.g. Artificial Intelligence'),
      ('skills', 'Skills', 'e.g. Flutter, Python, Machine Learning'),
      ('lookingFor', 'Looking For', 'e.g. Internship, Co-founder, Networking'),
    ],
    'founder': [
      ('startupName', 'Startup Name', 'e.g. TechVenture India'),
      ('startupStage', 'Startup Stage', 'e.g. Idea Stage, MVP, Revenue Stage'),
      ('industry', 'Industry', 'e.g. Fintech, EdTech, HealthTech'),
      (
        'startupDescription',
        'Startup Description',
        'What problem are you solving?',
      ),
      ('startupLocation', 'Location', 'e.g. Bangalore, Karnataka'),
      ('teamSize', 'Team Size', 'e.g. 5'),
      ('businessNeeds', 'Looking For', 'e.g. Funding, Mentors, Co-founders'),
    ],
    'mentor': [
      ('profession', 'Profession / Designation', 'e.g. CTO, Founder'),
      ('company', 'Company / Organization', 'e.g. Google, IIM Ahmedabad'),
      ('expertise', 'Expertise', 'e.g. Product, Tech, Finance, Marketing'),
      ('yearsExperience', 'Years of Experience', 'e.g. 10'),
      ('industry', 'Industry', 'e.g. SaaS, Fintech, Edtech'),
      ('mentorshipArea', 'Mentorship Areas', 'e.g. Startup, Marketing, Legal'),
      ('availability', 'Availability', 'e.g. Free, Paid, Group Sessions'),
    ],
    'investor': [
      ('investorType', 'Investor Type', 'e.g. Angel Investor, VC'),
      ('firmName', 'Firm Name', 'e.g. Accel Partners'),
      ('investmentRange', 'Investment Range', 'e.g. ₹10L – ₹1Cr'),
      (
        'preferredIndustries',
        'Preferred Industries',
        'e.g. Fintech, SaaS, D2C',
      ),
      ('preferredStage', 'Preferred Stage', 'e.g. Pre-Seed, Seed, Series A'),
      ('portfolioCompanies', 'Portfolio Companies', 'e.g. Zepto, Razorpay'),
    ],
    'college': [
      ('collegeName', 'College Name', 'e.g. Anna University'),
      ('collegeType', 'College Type', 'e.g. Engineering, Management'),
      ('cityState', 'City / State', 'e.g. Chennai, Tamil Nadu'),
      ('contactPersonName', 'Contact Person', 'e.g. Dr. Ramesh Kumar'),
      ('designation', 'Designation', 'e.g. Dean, Training & Placement Officer'),
      ('numberOfStudents', 'Number of Students', 'e.g. 5000'),
      ('interestedIn', 'Interested In', 'e.g. Startup Programs, Incubation'),
    ],
    'startup_enthusiast': [
      ('interestArea', 'Interest Areas', 'e.g. AI, Fintech, Gaming'),
      ('lookingFor', 'Looking For', 'e.g. Networking, Learning, Co-founder'),
    ],
  };

  static String _roleSectionLabel(String role) => switch (role) {
    'student' => 'Student Details',
    'founder' => 'Startup Details',
    'mentor' => 'Mentor Details',
    'investor' => 'Investor Details',
    'college' => 'College Details',
    'startup_enthusiast' => 'Your Interests',
    _ => 'Profile Details',
  };

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
    _locationController.dispose();
    for (final c in _roleDetailControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                                validator: _validateUsername,
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
                                readOnly: true,
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
                                controller: _locationController,
                                label: 'Location',
                                hintText: 'e.g. Bangalore, India',
                                keyboardType: TextInputType.streetAddress,
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
                          if (_currentUser != null &&
                              _currentUser!.role.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildRoleBanner(isDark),
                            const SizedBox(height: 20),
                            _buildRoleSection(isDark),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

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
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to edit your profile.')),
      );
      Navigator.of(context).pop();
      return;
    }
    final resolved = user;

    // Build role-detail controllers before setState so they're ready for build
    final fields = _roleFields[resolved.role] ?? [];
    for (final (key, _, _) in fields) {
      _roleDetailControllers[key] = TextEditingController(
        text: resolved.roleDetails[key]?.toString() ?? '',
      );
    }

    setState(() {
      _currentUser = resolved;
      _usernameController.text = resolved.username;
      _fullNameController.text = resolved.fullName.isEmpty
          ? resolved.displayName
          : resolved.fullName;
      _emailController.text = resolved.email;
      _phoneController.text = resolved.phone;
      _bioController.text = resolved.bio;
      _websiteController.text = resolved.websiteUrl;
      _locationController.text =
          resolved.roleDetails['location']?.toString() ?? '';
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
    final baseUser = _currentUser;
    if (baseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile is still loading.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final username = _usernameController.text.trim();
      final usernameAvailable = await ref
          .read(firestoreRepositoryProvider)
          .isUsernameAvailable(username, baseUser.uid);
      if (!usernameAvailable) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken.')),
        );
        return;
      }

      String avatarUrl = baseUser.avatarUrl;
      if (_pickedAvatarPath != null) {
        avatarUrl = await ref
            .read(firestoreRepositoryProvider)
            .uploadImage(_pickedAvatarPath!);
      }

      // Merge role-specific fields back, preserving any keys from other roles
      final updatedRoleDetails = Map<String, dynamic>.from(
        baseUser.roleDetails,
      );
      for (final entry in _roleDetailControllers.entries) {
        updatedRoleDetails[entry.key] = entry.value.text.trim();
      }
      updatedRoleDetails['location'] = _locationController.text.trim();

      final updatedUser = baseUser.copyWith(
        username: username,
        fullName: _fullNameController.text.trim(),
        email: baseUser.email,
        phone: _phoneController.text.trim(),
        displayName: _fullNameController.text.trim().isEmpty
            ? baseUser.displayName
            : _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        avatarUrl: avatarUrl,
        roleDetails: updatedRoleDetails,
      );

      await ref.read(authRepositoryProvider).updateUserData(updatedUser);
      if (!mounted) return;

      _currentUser = updatedUser;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).maybePop();
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to update profile',
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed. Please try again.')),
      );
    }
  }

  String? _validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Username is required';
    if (!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(text)) {
      return 'Use 3-24 letters, numbers or _';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[\+\d\-\s]{7,18}$');
    if (!phoneRegex.hasMatch(text)) return 'Enter a valid phone number';
    return null;
  }

  Widget _buildRoleBanner(bool isDark) {
    final role = _currentUser!.role;
    final label = role
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryDefault.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.primaryDefault,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.textSmall.copyWith(fontSize: 12),
                children: [
                  TextSpan(
                    text: 'Role: ',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      color: AppColors.primaryDefault,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  Your role cannot be changed after sign-up.',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection(bool isDark) {
    final role = _currentUser!.role;
    final fields = _roleFields[role] ?? [];
    if (fields.isEmpty) return const SizedBox.shrink();

    return _FormSection(
      label: _roleSectionLabel(role),
      isDark: isDark,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          AppTextField(
            controller:
                _roleDetailControllers[fields[i].$1] ?? TextEditingController(),
            label: fields[i].$2,
            hintText: fields[i].$3,
          ),
        ],
      ],
    );
  }

  Widget _avatarFallback(bool isDark) {
    return Container(
      width: 108,
      height: 108,
      color: isDark
          ? AppColors.darkSurface
          : AppColors.grayscaleSecondaryButton,
      child: Icon(
        Icons.person_rounded,
        size: 52,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.grayscaleButtonText,
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
