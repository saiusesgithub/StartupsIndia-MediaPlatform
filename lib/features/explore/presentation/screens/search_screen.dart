import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../../theme/style_guide.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../../home/presentation/providers/news_provider.dart';
import '../../../home/domain/models/news_article.dart';
import '../../domain/models/mock_explore_data.dart';
import '../widgets/topic_search_tile.dart';
import '../widgets/author_tile.dart';
import 'source_profile_screen.dart';

enum SearchTab { news, topics, author }

class SearchScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;
  final SearchTab initialTab;

  const SearchScreen({
    super.key,
    this.showBottomNav = true,
    this.initialTab = SearchTab.news,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late SearchTab _currentTab;
  final Set<String> _savedTopics = {'topic_1'};
  final Set<String> _followingAuthors = {'author_2'};

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            _buildSearchField(isDark),
            const SizedBox(height: 14),
            _buildTabBar(isDark),
            const SizedBox(height: 8),
            Expanded(child: _buildBodyList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/kabar_logo.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Startups India',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 22,
              color: AppColors.primaryDefault,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkInputBackground
                        : AppColors.grayscaleInputBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4757),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkInputBackground
              : AppColors.grayscaleInputBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          style: AppTypography.textSmall.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).setQuery(value);
            setState(() {});
          },
          onTap: () => _searchFocusNode.requestFocus(),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: AppTypography.textSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
              size: 20,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                    size: 20,
                  )
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                      setState(() {});
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                      size: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _tabItem('News', SearchTab.news, isDark),
          _tabItem('Topics', SearchTab.topics, isDark),
          _tabItem('Author', SearchTab.author, isDark),
        ],
      ),
    );
  }

  Widget _tabItem(String title, SearchTab tab, bool isDark) {
    final bool isActive = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = tab),
        child: Column(
          children: [
            Text(
              title,
              style: AppTypography.textSmall.copyWith(
                color: isActive
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleButtonText),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryDefault : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyList(bool isDark) {
    if (_currentTab == SearchTab.news) {
      final searchAsync = ref.watch(searchResultProvider);
      return searchAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Text(
                'No news found',
                style: AppTypography.textSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleButtonText,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: articles.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final article = articles[index];
              // Convert NewsArticleModel to NewsArticle
              final newsArticle = NewsArticle(
                id: article.id,
                authorId: article.authorId,
                category: article.category,
                headline: article.headline,
                sourceName: article.sourceName,
                sourceId: article.sourceId,
                sourceLogoAsset: article.sourceLogoAsset,
                thumbnailAsset: article.thumbnailAsset,
                timeAgo: formatArticleTimestamp(
                  article.createdAt,
                  fallback: article.timeAgo,
                ),
                body: article.body,
                likesCount: article.likesCount,
                commentsCount: article.commentsCount,
                isSourceFollowing: article.isSourceFollowing,
                isBookmarked: article.isBookmarked,
                isLiked: article.isLiked,
              );
              return NewsTile(article: newsArticle);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
        ),
      );
    }

    if (_currentTab == SearchTab.topics) {
      return ListView.builder(
        itemCount: MockExploreData.topics.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final topic = MockExploreData.topics[index];
          return TopicSearchTile(
            topic: topic,
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
      );
    }

    return ListView.builder(
      itemCount: MockExploreData.authors.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final author = MockExploreData.authors[index];
        return AuthorTile(
          author: author,
          isFollowing: _followingAuthors.contains(author.id),
          onTap: () {
            final source = MockExploreData.sourceProfileForAuthor(author);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SourceProfileScreen(source: source),
              ),
            );
          },
          onToggleFollow: () {
            setState(() {
              if (_followingAuthors.contains(author.id)) {
                _followingAuthors.remove(author.id);
              } else {
                _followingAuthors.add(author.id);
              }
            });
          },
        );
      },
    );
  }
}
