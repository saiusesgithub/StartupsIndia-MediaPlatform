import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      print("Login Executed!");
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hello\nAgain!',
                    style: AppTypography.displayLargeBold.copyWith(
                      color: AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back you\'ve\nbeen missed',
                    style: AppTypography.textLarge.copyWith(
                      color: AppColors.grayscaleBodyText,
                    ),
                  ),
                  const SizedBox(height: 48),

                  AppTextField(
                    controller: _usernameController,
                    label: 'Username*',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Invalid Username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _passwordController,
                    label: 'Password*',
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Invalid Password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? true);
                              },
                              activeColor: AppColors.primaryDefault,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              side: const BorderSide(color: AppColors.grayscaleBodyText),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: AppTypography.textSmall.copyWith(
                              color: AppColors.grayscaleBodyText,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          print("Forgot password tapped");
                        },
                        child: Text(
                          'Forgot the password ?',
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.linkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDefault,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: AppTypography.linkMedium.copyWith(
                        color: AppColors.grayscaleWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.grayscaleLine)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleBodyText,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.grayscaleLine)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.grayscaleSecondaryButton,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                          label: Text(
                            'Facebook',
                            style: AppTypography.linkMedium.copyWith(
                              color: AppColors.grayscaleButtonText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.grayscaleSecondaryButton,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.g_mobiledata, color: AppColors.grayscaleTitleActive, size: 28),
                          label: Text(
                            'Google',
                            style: AppTypography.linkMedium.copyWith(
                              color: AppColors.grayscaleButtonText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'don\'t have an account ? ',
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleBodyText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print("Navigate to Sign Up");
                        },
                        child: Text(
                          'Sign Up',
                          style: AppTypography.linkMedium.copyWith(
                            color: AppColors.primaryDefault,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
