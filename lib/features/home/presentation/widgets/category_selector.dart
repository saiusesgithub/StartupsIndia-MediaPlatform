import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

/// Horizontal scrollable category selector with active blue indicator.
/// Matches the Figma tab bar below the Trending section.
class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = cat == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? AppColors.primaryDefault
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: AppTypography.textSmall.copyWith(
                    color: isActive
                        ? AppColors.primaryDefault
                        : AppColors.grayscaleBodyText,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
