import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/mock_explore_data.dart';

class AuthorTile extends StatelessWidget {
  final AuthorItem author;
  final bool isFollowing;
  final VoidCallback onToggleFollow;
  final VoidCallback? onTap;

  const AuthorTile({
    super.key,
    required this.author,
    required this.isFollowing,
    required this.onToggleFollow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? AppColors.darkInputBackground
                  : AppColors.grayscaleSecondaryButton,
              backgroundImage: AssetImage(author.avatarAsset),
              onBackgroundImageError: (exception, stackTrace) {},
              child: author.avatarAsset.isEmpty
                  ? Icon(
                      Icons.person,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleButtonText,
                    )
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
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author.followers,
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
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
                backgroundColor: isFollowing
                    ? AppColors.primaryDefault
                    : Colors.transparent,
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
      ),
    );
  }
}
