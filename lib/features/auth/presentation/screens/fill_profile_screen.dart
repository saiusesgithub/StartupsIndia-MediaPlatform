import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
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

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
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

        // Create UserModel with the entered data
        final updatedUser = UserModel(
          uid: currentUser.uid,
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          displayName: _fullNameController.text.trim(),
          bio: 'Sharing updates and insights from around the world.',
          avatarUrl: _pickedImage?.path ?? 'assets/images/thumb_politics.png',
          websiteUrl: 'https://example.com',
          followersCount: 0,
          followingCount: 0,
          newsCount: 0,
        );

        // Save to Firebase
        await authRepo.updateUserData(updatedUser);

        if (!mounted) return;

        // Navigate to home and refresh the user data
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── App Bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isSubmitting ? null : () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back,
                          color: _isSubmitting ? Colors.grey : AppColors.grayscaleTitleActive,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Fill your Profile',
                          textAlign: TextAlign.center,
                          style: AppTypography.linkMedium.copyWith(
                            color: AppColors.grayscaleTitleActive,
                          ),
                        ),
                      ),
                      // Spacer to keep title centered
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),

                          // ── Avatar Picker ────────────────────────────
                          Center(
                            child: GestureDetector(
                              onTap: _isSubmitting ? null : _pickImage,
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Circle avatar
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: const Color(0xFFEEF1F4),
                                      backgroundImage: _pickedImage != null
                                          ? FileImage(_pickedImage!)
                                          : null,
                                      child: _pickedImage == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFFBDBDBD),
                                            )
                                          : null,
                                    ),
                                    // Camera icon badge
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryDefault,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Username ─────────────────────────────────
                          AppTextField(
                            controller: _usernameController,
                            label: 'Username',
                            hintText: 'wilsonfranci',
                          ),
                          const SizedBox(height: 16),

                          // ── Full Name ────────────────────────────────
                          AppTextField(
                            controller: _fullNameController,
                            label: 'Full Name',
                            hintText: 'Wilson Franci',
                          ),
                          const SizedBox(height: 16),

                          // ── Email Address (required) ─────────────────
                          AppTextField(
                            controller: _emailController,
                            label: 'Email Address*',
                            hintText: 'example@youremail.com',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Phone Number (required) ──────────────────
                          AppTextField(
                            controller: _phoneController,
                            label: 'Phone Number*',
                            hintText: '+62-8421-4512-2531',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              final phoneRegex = RegExp(r'^[\+\d\-\s]{7,15}$');
                              if (!phoneRegex.hasMatch(val.trim())) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Next Button (pinned at bottom) ───────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDefault,
                      disabledBackgroundColor: Colors.grey.shade400,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: AppTypography.linkMedium.copyWith(
                        color: AppColors.grayscaleWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withOpacity(0.12),
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
}
