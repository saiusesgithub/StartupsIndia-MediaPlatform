import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_format_helper.dart';
import '../../../../core/models/news_article_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/domain/models/community_model.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../domain/models/home_mock_data.dart';
import '../../domain/models/news_article.dart';
import '../../domain/models/startup_leader_entry.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/news_provider.dart';

final homeCurrentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) {
  return ref.read(authRepositoryProvider).getCurrentUserModel();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _heroController;
  int _heroPage = 0;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final next = (_heroPage + 1) % HomeMockData.featured.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendingAsync = ref.watch(trendingNewsProvider);
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isDark, isGuest)),
            SliverToBoxAdapter(child: _buildQuickActions(isDark, isGuest)),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildHeroBanner()),
            SliverToBoxAdapter(
              child: _buildSectionHeader('1', 'Trending Startup News', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildTrendingSection(trendingAsync, isDark, isGuest),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader('2', 'Funding Opportunities', isDark),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildFundingSection(isDark)),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader('3', 'Upcoming Events', isDark),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildEventsSection(isDark)),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader('4', 'Recommended Courses', isDark),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildCoursesSection(isDark)),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                '5',
                'Top Communities',
                isDark,
                onViewAll: () => Navigator.pushNamed(context, '/community-list'),
              ),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildCommunitiesSection(isDark)),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader('6', 'Startup Leaderboard', isDark),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildLeaderboard(isDark)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _gated(bool isGuest, Widget child) {
    if (!isGuest) return child;
    return GuestBlur(child: child);
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, bool isGuest) {
    final user = FirebaseAuth.instance.currentUser;
    final userModel = ref.watch(homeCurrentUserProvider).asData?.value;
    final avatarUrl = (userModel?.avatarUrl.isNotEmpty == true)
        ? userModel!.avatarUrl
        : user?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          // Logo wordmark
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Startups',
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryDefault,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: 'India',
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 20,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Search icon
          _HeaderIcon(
            icon: Icons.search_rounded,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          const SizedBox(width: 10),
          // Notification bell with badge (no dot for guests)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderIcon(
                icon: Icons.notifications_none_rounded,
                isDark: isDark,
                onTap: () => isGuest
                    ? Navigator.pushNamed(context, '/signup')
                    : Navigator.pushNamed(context, '/notifications'),
              ),
              if (!isGuest)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDefault,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          // Profile avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(
                context, isGuest ? '/signup' : '/profile'),
            child: ClipOval(
              child: Container(
                width: 36,
                height: 36,
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.grayscaleSecondaryButton,
                child: avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _avatarFallback(isDark),
                      )
                    : _avatarFallback(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(bool isDark) => Icon(
        Icons.person_rounded,
        size: 20,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.grayscaleButtonText,
      );

  // ── Quick Actions ───────────────────────────────────────────────────────────

  Widget _buildQuickActions(bool isDark, bool isGuest) {
    const actions = [
      (Icons.event_rounded, 'Join Event'),
      (Icons.school_rounded, 'Start Learning'),
      (Icons.handshake_outlined, 'Find Mentor'),
      (Icons.attach_money_rounded, 'Apply Funding'),
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final (icon, label) = actions[i];
          return _QuickActionCard(
            icon: icon,
            label: label,
            isDark: isDark,
            onTap: () => isGuest
                ? Navigator.pushNamed(context, '/signup')
                : _onQuickAction(label),
          );
        },
      ),
    );
  }

  void _onQuickAction(String label) {
    if (label == 'Start Learning') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label — coming soon!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryDefault,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDefault,
      ),
    );
  }

  // ── Hero Banner ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _heroController,
                itemCount: HomeMockData.featured.length,
                onPageChanged: (p) => setState(() => _heroPage = p),
                itemBuilder: (context, i) {
                  return _HeroSlide(story: HomeMockData.featured[i]);
                },
              ),
              // Page dots
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    HomeMockData.featured.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _heroPage == i ? 20 : 6,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _heroPage == i
                            ? AppColors.primaryDefault
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header with left red accent bar ─────────────────────────────────

  Widget _buildSectionHeader(
    String number,
    String title,
    bool isDark, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$number. $title',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          if (onViewAll != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.primaryDefault,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: AppColors.primaryDefault,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 1. Trending Startup News ─────────────────────────────────────────────────

  Widget _buildTrendingSection(
    AsyncValue<List<NewsArticleModel>> trendingAsync,
    bool isDark,
    bool isGuest,
  ) {
    return SizedBox(
      height: 200,
      child: trendingAsync.when(
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (context, index) => _SkeletonCard(isDark: isDark),
        ),
        error: (error, stack) => _buildEmptyHScroll(
          'No trending stories yet.',
          isDark,
        ),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyHScroll('No trending stories yet.', isDark);
          }
          // Guests see first 2 real cards + 1 locked teaser
          final visible = isGuest ? items.take(2).toList() : items;
          final extraCount = isGuest ? 1 : 0;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: visible.length + extraCount,
            itemBuilder: (context, i) {
              if (i < visible.length) {
                final item = visible[i];
                final article = _toNewsArticle(item);
                return _StoryCard(
                  article: article,
                  colorIndex: i,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/article-detail',
                    arguments: item,
                  ),
                );
              }
              return _LockedStoryCard(isDark: isDark);
            },
          );
        },
      ),
    );
  }

  // ── 2. Funding Opportunities ─────────────────────────────────────────────────

  Widget _buildFundingSection(bool isDark) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HomeMockData.funding.length,
        itemBuilder: (_, i) => _FundingCard(
          card: HomeMockData.funding[i],
          isDark: isDark,
        ),
      ),
    );
  }

  // ── 3. Upcoming Events ───────────────────────────────────────────────────────

  Widget _buildEventsSection(bool isDark) {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HomeMockData.events.length,
        itemBuilder: (_, i) =>
            _EventCard(event: HomeMockData.events[i], isDark: isDark),
      ),
    );
  }

  // ── 4. Recommended Courses ───────────────────────────────────────────────────

  Widget _buildCoursesSection(bool isDark) {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HomeMockData.courses.length,
        itemBuilder: (_, i) =>
            _CourseCard(course: HomeMockData.courses[i], isDark: isDark),
      ),
    );
  }

  // ── 5. Top Communities ───────────────────────────────────────────────────────

  Widget _buildCommunitiesSection(bool isDark) {
    final communitiesAsync = ref.watch(communitiesProvider);
    final communities = communitiesAsync.asData?.value ?? [];
    if (communities.isEmpty) {
      return const SizedBox(height: 80);
    }
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: communities.length,
        itemBuilder: (_, i) => _CommunityCard(
          community: communities[i],
          isDark: isDark,
        ),
      ),
    );
  }

  // ── 6. Startup Leaderboard ───────────────────────────────────────────────────

  Widget _buildLeaderboard(bool isDark) {
    final asyncData = ref.watch(leaderboardProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: asyncData.when(
        loading: () => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryDefault,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, s) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Could not load leaderboard',
              style: AppTypography.textSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ),
        ),
        data: (entries) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: Column(
            children: List.generate(entries.length, (i) {
              return _LeaderboardRow(
                entry: entries[i],
                isDark: isDark,
                showDivider: i < entries.length - 1,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHScroll(String msg, bool isDark) {
    return Center(
      child: Text(
        msg,
        style: AppTypography.textSmall.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText,
        ),
      ),
    );
  }

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

// ── Header icon button ─────────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleInputBackground,
          borderRadius: BorderRadius.circular(10),
          border: isDark
              ? Border.all(color: AppColors.darkBorder, width: 1)
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.grayscaleTitleActive,
        ),
      ),
    );
  }
}

// ── Quick Action Card ──────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleInputBackground,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryDefault),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero slide ─────────────────────────────────────────────────────────────────

class _HeroSlide extends StatelessWidget {
  final HomeFeaturedStory story;

  const _HeroSlide({required this.story});

  void _openStory(BuildContext context) {
    if (story.articleId != null && story.articleId!.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/article-detail',
        arguments: story.articleId,
      );
    } else {
      // Mock/placeholder stories fall back to the trending article list.
      Navigator.pushNamed(context, '/trending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openStory(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [story.gradientStart, story.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  story.badge,
                  style: AppTypography.textSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Headline
              Text(
                story.headline,
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 22,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              // Highlighted line
              Text(
                story.highlightLine,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryDefault,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle
              Text(
                story.subtitle,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // Read Full Story button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openStory(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read Full Story',
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grayscaleTitleActive,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.grayscaleTitleActive,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Story card (trending) ──────────────────────────────────────────────────────

const List<Color> _cardGradients = [
  Color(0xFF1A0A2E),
  Color(0xFF0A1628),
  Color(0xFF0D2137),
  Color(0xFF1C0A0A),
  Color(0xFF0A1C0A),
  Color(0xFF1A1A0A),
];

class _StoryCard extends StatelessWidget {
  final NewsArticle article;
  final int colorIndex;
  final VoidCallback onTap;

  const _StoryCard({
    required this.article,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _cardGradients[colorIndex % _cardGradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [bg, bg.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Thumbnail as subtle background
            if (article.thumbnailAsset.startsWith('http'))
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Opacity(
                    opacity: 0.25,
                    child: CachedNetworkImage(
                      imageUrl: article.thumbnailAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDefault,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: AppTypography.textSmall.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article.sourceName,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            // Time badge bottom-right
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  article.timeAgo,
                  style: AppTypography.textSmall.copyWith(
                    color: Colors.white,
                    fontSize: 9,
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
}

// ── Locked teaser card (guest mode, trailing trending card) ───────────────────

class _LockedStoryCard extends StatelessWidget {
  final bool isDark;

  const _LockedStoryCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/signup'),
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A2E), Color(0xFF0D0D0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primaryDefault.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryDefault.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.primaryDefault, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign up to\nread more',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryDefault,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Join Free →',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading card ──────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final bool isDark;

  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleSecondaryButton,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ── Funding card ───────────────────────────────────────────────────────────────

class _FundingCard extends StatelessWidget {
  final HomeFundingCard card;
  final bool isDark;

  const _FundingCard({required this.card, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    card.initial,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: card.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    Text(
                      card.sector,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successDefault.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'FUNDED',
              style: AppTypography.textSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.successDefault,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.amount,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          Text(
            card.stage,
            style: AppTypography.textSmall.copyWith(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event card ─────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final HomeEvent event;
  final bool isDark;

  const _EventCard({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.day,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      event.month,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
              const SizedBox(width: 3),
              Text(
                event.attendees,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Course card ────────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final HomeCourse course;
  final bool isDark;

  const _CourseCard({required this.course, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: course.categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              course.category,
              style: AppTypography.textSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: course.categoryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              course.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: 14,
                color: AppColors.primaryDefault,
              ),
              const SizedBox(width: 4),
              Text(
                course.duration,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Community card ─────────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final bool isDark;

  const _CommunityCard({required this.community, required this.isDark});

  String _fmtMembers(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K members';
    return '$n members';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: community.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                community.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  community.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
                Text(
                  _fmtMembers(community.memberCount),
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryDefault,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Join',
              style: AppTypography.textSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard row ────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final StartupLeaderEntry entry;
  final bool isDark;
  final bool showDivider;

  const _LeaderboardRow({
    required this.entry,
    required this.isDark,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final changeColor =
        entry.isPositive ? AppColors.successDefault : AppColors.errorDark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '#${entry.rank}',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isTop3
                        ? AppColors.primaryDefault
                        : isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    entry.name[0],
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: entry.color,
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
                      entry.name,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    Text(
                      entry.sector,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.formattedMarketCap,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.formattedChange,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: changeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
      ],
    );
  }
}

