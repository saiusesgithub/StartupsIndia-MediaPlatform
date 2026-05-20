import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/presentation/widgets/trending_card.dart';
import '../../domain/models/mock_explore_data.dart';
import 'search_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final Set<String> _savedTopics = <String>{'topic_2'};

  static final List<NewsArticle> _popularArticles =
      List<NewsArticle>.unmodifiable(<NewsArticle>[
        ...MockExploreData.news,
        ...MockExploreData.news,
      ]);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Explore',
                  style: AppTypography.displayMediumBold.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    height: 1.15,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Topic',
                      style: AppTypography.displaySmallBold.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/search',
                          arguments: SearchTab.communities,
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(56, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'See all',
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleButtonText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            SliverList.builder(
              itemCount: MockExploreData.topics.length,
              itemBuilder: (context, index) {
                final topic = MockExploreData.topics[index];
                return _ExploreTopicTile(
                  key: ValueKey<String>(topic.id),
                  topic: topic,
                  isDark: isDark,
                  isSaved: _savedTopics.contains(topic.id),
                  onToggleSave: () {
                    setState(() {
                      if (_savedTopics.contains(topic.id)) {
                        _savedTopics.remove(topic.id);
                      } else {
                        _savedTopics.add(topic.id);
                      }
                    });
                  },
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Popular Topic',
                  style: AppTypography.displaySmallBold.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: _popularArticles.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TrendingCard(
                      article: _popularArticles[index],
                      horizontalPadding: 0,
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }
}

class _ExploreTopicTile extends StatelessWidget {
  final TopicSearchItem topic;
  final bool isDark;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const _ExploreTopicTile({
    super.key,
    required this.topic,
    required this.isDark,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              topic.thumbnailAsset,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 60,
                  height: 60,
                  color: isDark
                      ? AppColors.darkInputBackground
                      : AppColors.grayscaleSecondaryButton,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleButtonText,
                    size: 18,
                  ),
                );
              },
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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: onToggleSave,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryDefault),
                backgroundColor: isSaved
                    ? AppColors.primaryDefault
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(
                isSaved ? 'Saved' : 'Save',
                style: AppTypography.textSmall.copyWith(
                  color: isSaved
                      ? AppColors.grayscaleWhite
                      : AppColors.primaryDefault,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
