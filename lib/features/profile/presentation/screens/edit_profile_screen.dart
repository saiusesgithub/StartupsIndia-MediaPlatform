import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _isLoading = false;
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
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAppBar(context),
                    const SizedBox(height: 10),
                    _buildAvatarEditor(),
                    const SizedBox(height: 18),
                    AppTextField(
                      controller: _usernameController,
                      label: 'Username',
                      hintText: 'wilsonfranci',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hintText: 'Wilson Franci',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address*',
                      hintText: 'example@youremail.com',
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number*',
                      hintText: '+62-8421-4512-2531',
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _bioController,
                      label: 'Bio',
                      hintText: 'Write a short bio',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _websiteController,
                      label: 'Website',
                      hintText: 'https://example.com',
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.grayscaleTitleActive,
            ),
          ),
          Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: AppTypography.textMedium.copyWith(
                color: AppColors.grayscaleTitleActive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : _submit,
            icon: const Icon(
              Icons.check_rounded,
              color: AppColors.grayscaleTitleActive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarEditor() {
    return Center(
      child: SizedBox(
        width: 126,
        height: 126,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 63,
              backgroundColor: AppColors.grayscaleSecondaryButton,
              backgroundImage: _pickedAvatarBytes == null
                  ? null
                  : MemoryImage(_pickedAvatarBytes!),
              child: _pickedAvatarBytes == null
                  ? const Icon(
                      Icons.person,
                      size: 58,
                      color: AppColors.grayscaleButtonText,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 4,
              child: GestureDetector(
                onTap: _isSubmitting ? null : _pickAvatar,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDefault,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: AppColors.grayscaleWhite,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 17,
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

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);

    final authRepo = ref.read(authRepositoryProvider);
    final user = await authRepo.getCurrentUserModel();

    if (!mounted) {
      return;
    }

    final UserModel resolved =
        user ??
        const UserModel(
          uid: 'demo_user',
          username: 'wilsonfranci',
          fullName: 'Wilson Franci',
          email: 'wilson@example.com',
          phone: '+62-8421-4512-2531',
          displayName: 'Wilson Franci',
          bio:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
          avatarUrl: 'assets/images/thumb_politics.png',
          websiteUrl: 'https://example.com',
          followersCount: 2156,
          followingCount: 567,
          newsCount: 23,
        );

    _currentUser = resolved;

    _usernameController.text = resolved.username;
    _fullNameController.text = resolved.fullName.isEmpty
        ? resolved.displayName
        : resolved.fullName;
    _emailController.text = resolved.email;
    _phoneController.text = resolved.phone;
    _bioController.text = resolved.bio;
    _websiteController.text = resolved.websiteUrl;

    setState(() => _isLoading = false);
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1080,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedAvatarPath = image.path;
      _pickedAvatarBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      avatarUrl: _pickedAvatarPath ?? baseUser.avatarUrl,
    );

    try {
      await ref.read(authRepositoryProvider).updateUserData(updatedUser);

      if (!mounted) {
        return;
      }

      _currentUser = updatedUser;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile Synced to Cloud!')));
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed. Please try again.')),
      );
    }
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[\+\d\-\s]{7,18}$');
    if (!phoneRegex.hasMatch(text)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
