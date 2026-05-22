import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../../theme/style_guide.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/report_repository.dart';
import '../providers/news_provider.dart';
import '../widgets/report_sheet.dart';

class SectionListArgs {
  final String title;
  final String category;

  const SectionListArgs({required this.title, required this.category});
}

enum _SectionFilter { all, latest, mostViewed, trending, series }

class SectionListScreen extends ConsumerStatefulWidget {
  final String title;
  final String category;

  const SectionListScreen({
    super.key,
    required this.title,
    required this.category,
  });

  @override
  ConsumerState<SectionListScreen> createState() => _SectionListScreenState();
}

class _SectionListScreenState extends ConsumerState<SectionListScreen> {
  _SectionFilter _filter = _SectionFilter.all;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final model = await ref.read(authRepositoryProvider).getCurrentUserModel();
      if (mounted) setState(() => _userId = model?.uid);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final articlesAsync = ref.watch(newsByCategoryProvider(widget.category));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildFilterBar(isDark),
            Expanded(
              child: articlesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDefault,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load articles',
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ),
                data: (items) {
                  final filtered = _applyFilter(items);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.grayscaleButtonText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No articles yet',
                              style: AppTypography.displaySmallBold.copyWith(
                                fontSize: 18,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.grayscaleTitleActive,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Check back soon for the latest ${widget.title.toLowerCase()} content.',
                              textAlign: TextAlign.center,
                              style: AppTypography.textSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleBodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _SectionArticleTile(
                      article: filtered[i],
                      isDark: isDark,
                      userId: _userId,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NewsArticleModel> _applyFilter(List<NewsArticleModel> items) {
    switch (_filter) {
      case _SectionFilter.all:
        return items;
      case _SectionFilter.latest:
        final sorted = [...items];
        sorted.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return sorted;
      case _SectionFilter.mostViewed:
        final sorted = [...items];
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        return sorted;
      case _SectionFilter.trending:
        return items.where((a) => a.isTrending).toList();
      case _SectionFilter.series:
        return items.where((a) => a.tags.isNotEmpty).toList();
    }
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 17,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    const labels = [
      (_SectionFilter.all, 'All'),
      (_SectionFilter.latest, 'Latest'),
      (_SectionFilter.mostViewed, 'Most Viewed'),
      (_SectionFilter.trending, 'Trending'),
      (_SectionFilter.series, 'Series'),
    ];

    return Container(
      height: 44,
      color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: labels.length,
        itemBuilder: (context, i) {
          final (filter, label) = labels[i];
          final selected = _filter == filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryDefault
                    : isDark
                        ? AppColors.darkBackground
                        : const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryDefault
                      : isDark
                          ? AppColors.darkBorder
                          : AppColors.grayscaleLine,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionArticleTile extends ConsumerStatefulWidget {
  final NewsArticleModel article;
  final bool isDark;
  final String? userId;

  const _SectionArticleTile({
    required this.article,
    required this.isDark,
    required this.userId,
  });

  @override
  ConsumerState<_SectionArticleTile> createState() =>
      _SectionArticleTileState();
}

class _SectionArticleTileState extends ConsumerState<_SectionArticleTile> {
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.article.isBookmarked ||
        (widget.userId != null &&
            widget.article.bookmarkedBy.contains(widget.userId));
  }

  String _fmtViews(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M views';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K views';
    if (v == 0) return '';
    return '$v views';
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final isDark = widget.isDark;
    final timeStr = formatArticleTimestamp(
      article.createdAt,
      fallback: article.timeAgo,
    );
    final viewStr = _fmtViews(article.viewCount);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/article-detail',
        arguments: article,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 88,
                height: 88,
                child: _buildThumbnail(article.thumbnailAsset, isDark),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    article.category.toUpperCase(),
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.primaryDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Headline
                  Text(
                    article.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Meta row
                  Row(
                    children: [
                      // Source logo
                      _SourceLogo(
                        url: article.sourceLogoAsset,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          article.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const _Dot(),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                        ),
                      ],
                      if (viewStr.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const _Dot(),
                        const SizedBox(width: 6),
                        Text(
                          viewStr,
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Bookmark
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Icon(
                          _isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 19,
                          color: _isBookmarked
                              ? AppColors.primaryDefault
                              : isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.grayscaleButtonText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3-dots menu
                      GestureDetector(
                        onTap: () => _showMenu(context),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 19,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleButtonText,
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

  Widget _buildThumbnail(String url, bool isDark) {
    final fallback = Container(
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleSecondaryButton,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText,
      ),
    );
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    }
    if (url.isNotEmpty) {
      return Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
    }
    return fallback;
  }

  Future<void> _toggleBookmark() async {
    final userId = widget.userId ??
        FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save articles')),
      );
      return;
    }
    final prev = _isBookmarked;
    setState(() => _isBookmarked = !prev);
    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleBookmark(widget.article.id, userId);
    } catch (_) {
      if (mounted) setState(() => _isBookmarked = prev);
    }
  }

  void _showMenu(BuildContext context) {
    final isDark = widget.isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetOption(
              icon: Icons.bookmark_border_rounded,
              label: _isBookmarked ? 'Remove bookmark' : 'Save article',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark();
              },
            ),
            _SheetOption(
              icon: Icons.flag_outlined,
              label: 'Report article',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                ReportSheet.show(
                  context,
                  title: 'Report article',
                  onSubmit: (reason) => ReportRepository().reportArticle(
                    articleId: widget.article.id,
                    reason: reason,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceLogo extends StatelessWidget {
  final String url;
  final bool isDark;

  const _SourceLogo({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Icon(Icons.newspaper, size: 10, color: AppColors.primaryDefault),
    );
    if (url.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 16,
          height: 16,
          fit: BoxFit.cover,
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        ),
      );
    }
    return fallback;
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.grayscaleButtonText,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 14,
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
