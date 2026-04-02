import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/mock_explore_data.dart';

class AuthorTile extends StatelessWidget {
  final AuthorItem author;
  final bool isFollowing;
  final VoidCallback onToggleFollow;

  const AuthorTile({
    super.key,
    required this.author,
    required this.isFollowing,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayscaleLine),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.grayscaleSecondaryButton,
            backgroundImage: AssetImage(author.avatarAsset),
            onBackgroundImageError: (exception, stackTrace) {},
            child: author.avatarAsset.isEmpty
                ? const Icon(Icons.person, color: AppColors.grayscaleButtonText)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.name,
                  style: AppTypography.textMedium.copyWith(
                    color: AppColors.grayscaleTitleActive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  author.followers,
                  style: AppTypography.textSmall.copyWith(
                    color: AppColors.grayscaleBodyText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onToggleFollow,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(104, 36),
              backgroundColor:
                  isFollowing ? AppColors.primaryDefault : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppColors.primaryDefault),
              ),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: AppTypography.textSmall.copyWith(
                color: isFollowing ? Colors.white : AppColors.primaryDefault,
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
