import 'package:flutter/material.dart';

import '../../../../theme/style_guide.dart';
import '../../domain/models/home_mock_data.dart';

class CoursesAllScreen extends StatelessWidget {
  const CoursesAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recommended Courses',
          style: AppTypography.displaySmallBold.copyWith(
            fontSize: 17,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: HomeMockData.courses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CourseTile(
          course: HomeMockData.courses[i],
          isDark: isDark,
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final HomeCourse course;
  final bool isDark;

  const _CourseTile({required this.course, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: course.categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.play_circle_outline_rounded,
              color: course.categoryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: course.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.category,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: course.categoryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  course.title,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
              const SizedBox(height: 3),
              Text(
                course.duration,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
