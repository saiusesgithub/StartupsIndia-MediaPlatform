import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/models/news_article_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/news_article.dart';
import '../../domain/models/news_feed_data.dart';
import '../providers/news_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/news_tile.dart';
import '../widgets/trending_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = true});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  String _selectedCategory = 'All';

  List<NewsArticle> get _filteredArticles {
    if (_selectedCategory == 'All') return NewsFeedData.latestArticles;
    return NewsFeedData.latestArticles
        .where(
          (a) => a.category.toLowerCase() == _selectedCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final latestNewsAsync = ref.watch(latestNewsProvider);
    final trendingNewsAsync = ref.watch(trendingNewsProvider);

    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,

      // ── Bottom Navigation Bar ───────────────────────────────────────
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,

      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Custom AppBar ─────────────────────────────────────────
            SliverToBoxAdapter(child: _buildAppBar()),

            // ── Search & Filter ───────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar()),

            // ── Trending Section ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Trending',
                onSeeAllTap: () => Navigator.pushNamed(context, '/trending'),
              ),
            ),
            SliverToBoxAdapter(
              child: trendingNewsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        'No trending articles yet.',
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleBodyText,
                        ),
                      ),
                    );
                  }

                  return TrendingCard(article: _toNewsArticle(items.first));
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDefault,
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Failed to load trending: $error',
                    style: AppTypography.textSmall.copyWith(color: Colors.red),
                  ),
                ),
              ),
            ),

            // ── Category Selector ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryHeaderDelegate(
                selectedCategory: _selectedCategory,
                categories: NewsFeedData.categories,
                onCategorySelected: (cat) {
                  setState(() => _selectedCategory = cat);
                },
              ),
            ),

            // ── Latest Section Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latest',
                      style: AppTypography.displaySmallBold.copyWith(
                        fontSize: 18,
                        color: AppColors.grayscaleTitleActive,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'See all',
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.primaryDefault,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Latest Feed ───────────────────────────────────────────
            // Using SliverList.builder for efficient rendering.
            // To swap for Firebase: replace _filteredArticles with a
            // StreamBuilder wrapping a Firestore .snapshots() call.
            SliverToBoxAdapter(
              child: latestNewsAsync.when(
                data: (items) {
                  final mapped = items
                      .map(_toNewsArticle)
                      .toList(growable: false);
                  final filtered = _selectedCategory == 'All'
                      ? mapped
                      : mapped
                            .where(
                              (a) =>
                                  a.category.toLowerCase() ==
                                  _selectedCategory.toLowerCase(),
                            )
                            .toList(growable: false);

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 48,
                        horizontal: 24,
                      ),
                      child: Center(
                        child: Text(
                          'No articles in this category yet.',
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleBodyText,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          NewsTile(article: filtered[index]),
                          if (index < filtered.length - 1)
                            const Divider(
                              height: 1,
                              indent: 24,
                              endIndent: 24,
                              color: AppColors.grayscaleLine,
                            ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDefault,
                    ),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Failed to load latest news: $error',
                    style: AppTypography.textSmall.copyWith(color: Colors.red),
                  ),
                ),
              ),
            ),

            // ── Bottom padding ────────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Temporary debug section ───────────────────────────────
            SliverToBoxAdapter(child: _buildDebugSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Startups India text logo
          RichText(
            text: TextSpan(
              children: [
                WidgetSpan(
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDefault,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _logoLine(14),
                        const SizedBox(height: 2),
                        _logoLine(10),
                        const SizedBox(height: 2),
                        _logoLine(7),
                      ],
                    ),
                  ),
                ),
                TextSpan(
                  text: 'Startups India',
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 22,
                    color: AppColors.primaryDefault,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Notification bell
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

  Widget _logoLine(double width) => Container(
    width: width,
    height: 2,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  // ── Search Bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.grayscaleInputBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.grayscaleBodyText,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: AppTypography.textSmall.copyWith(
                        color: AppColors.grayscaleTitleActive,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleButtonText,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filter button
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAllTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 18,
              color: AppColors.grayscaleTitleActive,
            ),
          ),
          GestureDetector(
            onTap: onSeeAllTap,
            child: Text(
              'See all',
              style: AppTypography.textSmall.copyWith(
                color: AppColors.primaryDefault,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    const activeColor = AppColors.primaryDefault;
    const inactiveColor = AppColors.grayscaleButtonText;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grayscaleWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/explore');
            return;
          }
          setState(() => _navIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        selectedLabelStyle: AppTypography.textSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.textSmall.copyWith(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_rounded),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: 'Bookmark',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ── Temporary Debug Section ───────────────────────────────────────────
  Widget _buildDebugSection() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCC00), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Color(0xFFB38600),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Debug Info',
                  style: AppTypography.textSmall.copyWith(
                    color: const Color(0xFFB38600),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _debugRow('Email', user?.email ?? '— not signed in —'),
            const SizedBox(height: 4),
            _debugRow('UID', user?.uid ?? '— not signed in —'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorDark,
                  side: const BorderSide(color: AppColors.errorDark),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 16),
                label: Text(
                  'Sign Out',
                  style: AppTypography.textSmall.copyWith(
                    color: AppColors.errorDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _debugRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 48,
        child: Text(
          '$label:',
          style: AppTypography.textSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.grayscaleTitleActive,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          style: AppTypography.textSmall.copyWith(
            fontSize: 11,
            color: AppColors.grayscaleBodyText,
          ),
        ),
      ),
    ],
  );

  NewsArticle _toNewsArticle(NewsArticleModel model) {
    return NewsArticle(
      id: model.id,
      authorId: model.authorId,
      category: model.category,
      headline: model.headline,
      sourceName: model.sourceName,
      sourceId: model.sourceId,
      sourceLogoAsset: model.sourceLogoAsset,
      thumbnailAsset: model.thumbnailAsset,
      timeAgo: formatArticleTimestamp(model.createdAt, fallback: model.timeAgo),
      body: model.body,
      likesCount: model.likesCount,
      commentsCount: model.commentsCount,
      isSourceFollowing: model.isSourceFollowing,
      isBookmarked: model.isBookmarked,
      isLiked: model.isLiked,
    );
  }
}

// ── SliverPersistentHeaderDelegate for pinned CategorySelector ─────────────
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;

  _CategoryHeaderDelegate({
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.grayscaleWhite,
      child: Column(
        children: [
          Expanded(
            child: CategorySelector(
              categories: categories,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
            ),
          ),
          const Divider(height: 1, color: AppColors.grayscaleLine),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.selectedCategory != selectedCategory;
}
