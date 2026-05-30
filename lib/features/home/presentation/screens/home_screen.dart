import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/utils/app_urls.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/home_mock_data.dart';
import '../providers/news_provider.dart';
import 'section_list_screen.dart';

// Section definitions: (label, category, icon)
const _kSections = [
  ('Top News', ''),
  ('Startups Stories', 'startup'),
  ('Entrepreneur Stories', 'entrepreneur'),
  ('Podcasts', 'podcast'),
  ('Funding Opportunities', 'funding'),
  ('Women', 'women'),
  ('Startup Learnings', 'learning'),
];

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
      if (!mounted) return;
      final latest = ref.read(latestNewsProvider).asData?.value ?? [];
      final count = latest.take(5).length;
      if (count <= 1) return;
      final next = (_heroPage + 1) % count;
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
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.grayscaleWhite,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(isDark, isGuest)),
            SliverToBoxAdapter(child: _buildHeroBanner(isDark)),
            // 8 article sections
            for (int i = 0; i < _kSections.length; i++) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  '${i + 1}',
                  _kSections[i].$1,
                  isDark,
                  onViewAll: () =>
                      _openSection(_kSections[i].$1, _kSections[i].$2),
                ),
              ),
              SliverToBoxAdapter(
                child: _kSections[i].$2 == 'podcast'
                    ? _buildPodcastSection(isDark, isGuest: isGuest)
                    : _buildArticleSection(
                        _kSections[i].$2,
                        isDark,
                        isGuest: isGuest,
                      ),
              ),
            ],
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                '8',
                'Upcoming Events',
                isDark,
                onViewAll: () => launchExternalUrl(AppUrls.events),
              ),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildEventsSection(isDark)),
            ),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                '9',
                'Courses',
                isDark,
                onViewAll: () => launchExternalUrl(AppUrls.programs),
              ),
            ),
            SliverToBoxAdapter(
              child: _gated(isGuest, _buildCoursesSection(isDark)),
            ),
            SliverToBoxAdapter(child: _buildProCta(isDark)),
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

  void _openSection(String title, String category) {
    Navigator.pushNamed(
      context,
      '/section-list',
      arguments: SectionListArgs(title: title, category: category),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, bool isGuest) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Startups',
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 18,
                    color: AppColors.primaryDefault,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: 'India',
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 18,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _HeaderIcon(
            icon: Icons.search_rounded,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, '/search'),
          ),
          const SizedBox(width: 10),
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
        ],
      ),
    );
  }

  // ── Hero Banner ──────────────────────────────────────────────────────────

  Widget _buildHeroBanner(bool isDark) {
    final latestAsync = ref.watch(latestNewsProvider);
    final articles = latestAsync.asData?.value ?? [];
    final heroArticles = articles.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          child: heroArticles.isEmpty
              ? _buildHeroSkeleton(isDark)
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _heroController,
                      itemCount: heroArticles.length,
                      onPageChanged: (p) => setState(() => _heroPage = p),
                      itemBuilder: (context, i) =>
                          _RealHeroSlide(article: heroArticles[i]),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          heroArticles.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: _heroPage == i ? 18 : 5,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: _heroPage == i
                                  ? AppColors.primaryDefault
                                  : Colors.white.withValues(alpha: 0.5),
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

  Widget _buildHeroSkeleton(bool isDark) {
    final base = isDark
        ? const Color(0xFF1A2636)
        : AppColors.grayscaleSecondaryButton;
    final highlight = isDark
        ? const Color(0xFF263547)
        : AppColors.grayscaleLine;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    String number,
    String title,
    bool isDark, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
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

  // ── Article section (Firestore-backed horizontal scroll) ─────────────────

  Widget _buildArticleSection(
    String category,
    bool isDark, {
    required bool isGuest,
  }) {
    final articlesAsync = ref.watch(homeNewsByCategoryProvider(category));
    const guestPreviewLimit = 3;
    return SizedBox(
      height: 200,
      child: articlesAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, _) => _SkeletonCard(isDark: isDark),
        ),
        error: (_, _) => _buildEmptySection('No articles yet', isDark),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptySection('No articles yet', isDark);
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final card = _HomeSectionCard(
                key: ValueKey(items[i].id),
                article: items[i],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/article-detail',
                  arguments: items[i],
                ),
              );
              if (!isGuest || i < guestPreviewLimit) return card;
              return SizedBox(
                width: 167,
                child: GuestBlur(
                  borderRadius: BorderRadius.circular(14),
                  label: 'Sign Up',
                  child: card,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Podcast section ───────────────────────────────────────────────────────

  Widget _buildPodcastSection(bool isDark, {required bool isGuest}) {
    final articlesAsync = ref.watch(homeNewsByCategoryProvider('podcast'));
    const guestPreviewLimit = 3;
    return SizedBox(
      height: 200,
      child: articlesAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, _) => _SkeletonCard(isDark: isDark),
        ),
        error: (_, _) => _buildEmptySection('No podcasts yet', isDark),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptySection('No podcasts yet', isDark);
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final card = _HomeSectionCard(
                key: ValueKey(items[i].id),
                article: items[i],
                isPodcast: true,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/article-detail',
                  arguments: items[i],
                ),
              );
              if (!isGuest || i < guestPreviewLimit) return card;
              return SizedBox(
                width: 167,
                child: GuestBlur(
                  borderRadius: BorderRadius.circular(14),
                  label: 'Sign Up',
                  child: card,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Events section ────────────────────────────────────────────────────────

  Widget _buildEventsSection(bool isDark) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HomeMockData.events.length,
        itemBuilder: (_, i) =>
            _EventCard(event: HomeMockData.events[i], isDark: isDark),
      ),
    );
  }

  // ── Courses section ───────────────────────────────────────────────────────

  Widget _buildCoursesSection(bool isDark) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: HomeMockData.courses.length,
        itemBuilder: (_, i) =>
            _CourseCard(course: HomeMockData.courses[i], isDark: isDark),
      ),
    );
  }

  Widget _buildEmptySection(String msg, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 32,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleButtonText,
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCta(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/pro'),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A130F) : const Color(0xFFFFF1EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryDefault.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primaryDefault,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want more from StartupsIndia?',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to Pro for premium startup tools and early access.',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryDefault,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable hero badge ───────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textSmall.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ReadFullStoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReadFullStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: AppColors.grayscaleTitleActive,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Real hero slide (uses Firestore trending article) ─────────────────────────

class _ArticleBackgroundImage extends StatelessWidget {
  final NewsArticleModel article;
  final Color fallbackColor;

  const _ArticleBackgroundImage({
    required this.article,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final featuredImage = article.featuredImageUrl.trim();
    final thumbnail = article.thumbnailAsset.trim();
    final image = featuredImage.isNotEmpty ? featuredImage : thumbnail;
    final fallback = Container(color: fallbackColor);

    if (image.isEmpty) return fallback;
    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    }

    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _RealHeroSlide extends StatelessWidget {
  final NewsArticleModel article;
  const _RealHeroSlide({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/article-detail', arguments: article),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ArticleBackgroundImage(
            article: article,
            fallbackColor: const Color(0xFF1A0A2E),
          ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _CategoryBadge(
                  label: article.category.isEmpty ? 'NEWS' : article.category,
                ),
                const SizedBox(height: 8),
                Text(
                  article.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ReadFullStoryButton(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/article-detail',
                        arguments: article,
                      ),
                    ),
                    const Spacer(),
                    if (article.sourceName.isNotEmpty) ...[
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        article.timeAgo,
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home section card ─────────────────────────────────────────────────────────

class _HomeSectionCard extends StatelessWidget {
  final NewsArticleModel article;
  final bool isPodcast;
  final VoidCallback onTap;

  const _HomeSectionCard({
    super.key,
    required this.article,
    required this.onTap,
    this.isPodcast = false,
  });

  String _fmtViews(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    if (v == 0) return '';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFF0D1B2E);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cardBg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ArticleBackgroundImage(article: article, fallbackColor: cardBg),
            // Gradient overlay (bottom-heavy)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Podcast play icon overlay
            if (isPodcast)
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            // Top: category pill
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryDefault,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (article.category.isEmpty ? 'NEWS' : article.category)
                      .toUpperCase(),
                  style: AppTypography.textSmall.copyWith(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Bottom: title + meta
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (article.timeAgo.isNotEmpty)
                        Text(
                          article.timeAgo,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                        ),
                      if (article.timeAgo.isNotEmpty &&
                          article.viewCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          width: 2,
                          height: 2,
                          decoration: const BoxDecoration(
                            color: Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      if (article.viewCount > 0)
                        Text(
                          '${_fmtViews(article.viewCount)} views',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 9,
                            color: Colors.white70,
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

// ── Skeleton loading card ─────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? const Color(0xFF1A2636)
        : AppColors.grayscaleSecondaryButton;
    final highlight = isDark
        ? const Color(0xFF263547)
        : AppColors.grayscaleLine;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Header icon button ────────────────────────────────────────────────────────

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
          color: isDark
              ? AppColors.darkSurface
              : AppColors.grayscaleInputBackground,
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

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final HomeEvent event;
  final bool isDark;

  const _EventCard({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
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
        ],
      ),
    );
  }
}

// ── Course card ───────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final HomeCourse course;
  final bool isDark;

  const _CourseCard({required this.course, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
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
