import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';

class FillProfileScreen extends StatefulWidget {
  const FillProfileScreen({super.key});

  @override
  State<FillProfileScreen> createState() => _FillProfileScreenState();
}

class _FillProfileScreenState extends State<FillProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Collect profile data locally for later Firebase push
      final Map<String, dynamic> userData = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'avatarPath': _pickedImage?.path,
      };
      debugPrint('User Profile: $userData');

      // Last step of onboarding – clear entire stack and go home
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
        child: Column(
          children: [
            // ── App Bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.grayscaleTitleActive,
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
                          onTap: _pickImage,
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
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDefault,
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
      ),
    );
  }
}
