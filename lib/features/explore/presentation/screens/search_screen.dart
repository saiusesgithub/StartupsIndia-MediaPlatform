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
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchField(),
            const SizedBox(height: 14),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildBodyList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
                    color: AppColors.grayscaleInputBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.grayscaleTitleActive,
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grayscaleInputBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          style: AppTypography.textSmall.copyWith(
            color: AppColors.grayscaleTitleActive,
          ),
          onChanged: (value) {
            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
            ref.read(searchQueryProvider.notifier).state = value;
          },
          onTap: () => _searchFocusNode.requestFocus(),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: AppTypography.textSmall.copyWith(
              color: AppColors.grayscaleButtonText,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.grayscaleBodyText,
              size: 20,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? const Icon(
                    Icons.search_rounded,
                    color: AppColors.grayscaleBodyText,
                    size: 20,
                  )
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
                      ref.read(searchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.grayscaleBodyText,
                      size: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _tabItem('News', SearchTab.news),
          _tabItem('Topics', SearchTab.topics),
          _tabItem('Author', SearchTab.author),
        ],
      ),
    );
  }

  Widget _tabItem(String title, SearchTab tab) {
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
                    ? AppColors.grayscaleTitleActive
                    : AppColors.grayscaleButtonText,
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

  Widget _buildBodyList() {
    if (_currentTab == SearchTab.news) {
      final searchAsync = ref.watch(searchResultProvider);
      return searchAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Text(
                'No news found',
                style: AppTypography.textSmall.copyWith(
                  color: AppColors.grayscaleButtonText,
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
        error: (error, _) => Center(child: Text('Error: $error')),
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
