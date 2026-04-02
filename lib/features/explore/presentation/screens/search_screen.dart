import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../theme/style_guide.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../domain/models/mock_explore_data.dart';
import '../widgets/topic_search_tile.dart';
import '../widgets/author_tile.dart';

enum SearchTab { news, topics, author }

class SearchScreen extends StatefulWidget {
  final bool showBottomNav;

  const SearchScreen({super.key, this.showBottomNav = true});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  SearchTab _currentTab = SearchTab.news;
  final Set<String> _savedTopics = {'topic_1'};
  final Set<String> _followingAuthors = {'author_2'};

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
            'Kabar',
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
            suffixIcon: IconButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _searchController.clear();
                }
              },
              icon: Icon(
                _searchController.text.isEmpty
                    ? Icons.tune_rounded
                    : Icons.close_rounded,
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
                color:
                    isActive ? AppColors.primaryDefault : Colors.transparent,
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
      return ListView.builder(
        itemCount: MockExploreData.news.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return NewsTile(article: MockExploreData.news[index]);
        },
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
