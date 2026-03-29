import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      appBar: AppBar(
        title: Text(
          'Home',
          style: AppTypography.displaySmallBold.copyWith(
            color: AppColors.grayscaleTitleActive,
          ),
        ),
        backgroundColor: AppColors.grayscaleWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Welcome to the News App!',
          style: AppTypography.textLarge.copyWith(
            color: AppColors.grayscaleBodyText,
          ),
        ),
      ),
    );
  }
}
