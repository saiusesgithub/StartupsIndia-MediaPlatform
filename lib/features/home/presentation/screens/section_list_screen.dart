import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../../core/utils/app_error_reporter.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/report_repository.dart';
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
  final List<NewsArticleModel> _articles = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadInitialArticles();
  }

  @override
  void didUpdateWidget(covariant SectionListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadInitialArticles();
    }
  }

  Future<void> _loadUserId() async {
    try {
      final model = await ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
      if (mounted) setState(() => _userId = model?.uid);
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to initialize section-list user',
      );
    }
  }

  Future<void> _loadInitialArticles() async {
    setState(() {
      _articles.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoadingInitial = true;
      _loadError = null;
    });

    try {
      final page = await ref
          .read(firestoreRepositoryProvider)
          .fetchNewsByCategoryPage(widget.category);
      if (!mounted) return;
      final sorted = [...page.articles]
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
      setState(() {
        _articles.addAll(sorted);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoadingInitial = false;
      });
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to load section articles',
      );
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load articles';
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _loadError = null;
    });

    try {
      final page = await ref
          .read(firestoreRepositoryProvider)
          .fetchNewsByCategoryPage(widget.category, startAfter: _lastDocument);
      if (!mounted) return;
      final sorted = [...page.articles]
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime(0);
          final bTime = b.createdAt ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
      setState(() {
        _articles.addAll(sorted);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to load more section articles',
      );
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load more articles';
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = FirebaseAuth.instance.currentUser == null;
    const guestPreviewLimit = 3;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildFilterBar(isDark),
            Expanded(
              child: _isLoadingInitial
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDefault,
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final filtered = _applyFilter(_articles);
                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
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
                                    style: AppTypography.displaySmallBold
                                        .copyWith(
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
                          itemCount: filtered.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == filtered.length) {
                              return _LoadMoreButton(
                                isDark: isDark,
                                isLoading: _isLoadingMore,
                                errorText: _loadError,
                                onTap: _loadMoreArticles,
                              );
                            }
                            final tile = _SectionArticleTile(
                              article: filtered[i],
                              isDark: isDark,
                              userId: _userId,
                            );
                            if (!isGuest || i < guestPreviewLimit) return tile;
                            return GuestBlur(
                              borderRadius: BorderRadius.circular(14),
                              label: 'Sign Up',
                              child: tile,
                            );
                          },
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
        return items;
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
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _LoadMoreButton extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onTap;

  const _LoadMoreButton({
    required this.isDark,
    required this.isLoading,
    required this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.grayscaleBodyText;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Column(
        children: [
          if (errorText != null) ...[
            Text(
              errorText!,
              style: AppTypography.textSmall.copyWith(
                color: AppColors.errorDark,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
          ],
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.grayscaleWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.grayscaleLine,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDefault,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Load more articles',
                          style: AppTypography.textSmall.copyWith(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.expand_more_rounded,
                          color: secondaryColor,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ],
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
    _isBookmarked =
        widget.article.isBookmarked ||
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
      onTap: () =>
          Navigator.pushNamed(context, '/article-detail', arguments: article),
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
                child: _buildThumbnail(
                  article.featuredImageUrl.isNotEmpty
                      ? article.featuredImageUrl
                      : article.thumbnailAsset,
                  isDark,
                ),
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
                      _SourceLogo(url: article.sourceLogoAsset, isDark: isDark),
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
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.grayscaleButtonText,
      ),
    );
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    }
    if (url.isNotEmpty) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }

  Future<void> _toggleBookmark() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      showGuestAuthPrompt(
        context,
        title: 'Sign in to save articles',
        message: 'Create an account to bookmark articles and read them later.',
      );
      return;
    }
    final prev = _isBookmarked;
    setState(() => _isBookmarked = !prev);
    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleBookmark(widget.article.id, userId);
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to bookmark section article',
      );
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
      child: const Icon(
        Icons.newspaper,
        size: 10,
        color: AppColors.primaryDefault,
      ),
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
