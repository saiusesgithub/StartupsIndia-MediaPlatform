import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startups_india_media_platform/theme/style_guide.dart';

class OnboardingModel {
  final String title;
  final String subtitle;
  final String imagePath;

  OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingModel> _pages = [
    OnboardingModel(
      title: "Lorem Ipsum is simply\ndummy",
      subtitle: "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
      imagePath: "assets/images/onboarding1_img.png",
    ),
    OnboardingModel(
      title: "Lorem Ipsum is simply\ndummy",
      subtitle: "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
      imagePath: "assets/images/onboarding2_img.png",
    ),
    OnboardingModel(
      title: "Lorem Ipsum is simply\ndummy",
      subtitle: "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
      imagePath: "assets/images/onboarding3_img.png",
    ),
  ];

  void _nextPage() async {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Handle "Get Started" tap
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstRun', false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: Column(
        children: [
          // Expand PageView to take up most of the screen
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Column(
                  children: [
                    // Figma instances are 428x584 originally, let's keep them proportional
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: double.infinity,
                      child: Image.asset(
                        page.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              page.title,
                              style: AppTypography.displaySmallBold.copyWith(
                                color: AppColors.grayscaleTitleActive,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              page.subtitle,
                              style: AppTypography.textMedium.copyWith(
                                color: AppColors.grayscaleBodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Bottom Navigation Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Animated Dots Indicator
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 5),
                      height: 14,
                      width: _currentIndex == index ? 30 : 14,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? AppColors.primaryDefault
                            : const Color(0xFFA0A3BD), // Grayscale/Placeholder
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
                
                // Back & Next/Get Started Buttons
                Row(
                  children: [
                    if (_currentIndex > 0)
                      TextButton(
                        onPressed: _previousPage,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB0B3B8), // Darkmode/Body
                        ),
                        child: Text(
                          'Back',
                          style: AppTypography.linkMedium.copyWith(
                            color: const Color(0xFFB0B3B8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDefault,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        _currentIndex == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: AppTypography.linkMedium.copyWith(
                          color: AppColors.grayscaleWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
