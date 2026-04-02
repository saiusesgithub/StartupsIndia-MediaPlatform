import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/mock_explore_data.dart';

class TopicSearchTile extends StatelessWidget {
  final TopicSearchItem topic;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const TopicSearchTile({
    super.key,
    required this.topic,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayscaleLine),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              topic.thumbnailAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
                color: AppColors.grayscaleSecondaryButton,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  size: 18,
                  color: AppColors.grayscaleButtonText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: AppTypography.textMedium.copyWith(
                    color: AppColors.grayscaleTitleActive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textSmall.copyWith(
                    color: AppColors.grayscaleBodyText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onToggleSave,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(76, 34),
              backgroundColor:
                  isSaved ? AppColors.primaryDefault : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppColors.primaryDefault),
              ),
            ),
            child: Text(
              isSaved ? 'Saved' : 'Save',
              style: AppTypography.textSmall.copyWith(
                color: isSaved ? Colors.white : AppColors.primaryDefault,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
