import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class SelectableTopicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableTopicChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDefault : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primaryDefault : AppColors.grayscaleBodyText,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.linkMedium.copyWith(
            color: isSelected ? AppColors.grayscaleWhite : AppColors.grayscaleBodyText,
          ),
        ),
      ),
    );
  }
}
