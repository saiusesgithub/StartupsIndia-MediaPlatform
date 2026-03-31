import 'package:flutter/material.dart';
import '../../domain/models/news_article.dart';
import '../../../../theme/style_guide.dart';

/// Reusable tile for the 'Latest' news feed section.
/// Matches the Figma design: thumbnail left, category/headline/source right.
class NewsTile extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;

  const NewsTile({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                article.thumbnailAsset,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: AppColors.grayscaleSecondaryButton,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.grayscaleButtonText),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Text block ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Text(
                    article.category.toUpperCase(),
                    style: AppTypography.textSmall.copyWith(
                      color: AppColors.primaryDefault,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Headline
                  Text(
                    article.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      color: AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Source row: logo + name + time
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.asset(
                          article.sourceLogoAsset,
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 20,
                            height: 20,
                            color: AppColors.grayscaleLine,
                            child: const Icon(Icons.newspaper,
                                size: 12, color: AppColors.grayscaleButtonText),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          article.sourceName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleBodyText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.grayscaleButtonText),
                      const SizedBox(width: 3),
                      Text(
                        article.timeAgo,
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleButtonText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
