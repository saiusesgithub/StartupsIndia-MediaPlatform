import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/app_text_field.dart';
import 'login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // 2 seconds loading simulation
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // Navigate to Home replacing entire auth stack identically
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
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
                    'Hello!',
                    style: AppTypography.displayLargeBold.copyWith(
                      color: AppColors.primaryDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signup to get Started',
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

                  // To strictly keep exact layout as requested, keeping Remember Me alignment
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
                      // Intentionally empty for exact padding mapping, signup has no forgot password
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDefault,
                      disabledBackgroundColor: AppColors.primaryDefault,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.grayscaleWhite,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Sign Up',
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
                          icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
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
                          icon: const FaIcon(FontAwesomeIcons.google, color: AppColors.grayscaleTitleActive, size: 22),
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
                        'Already have an account ? ',
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleBodyText,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Swap back to Login cleanly
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'Login',
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
