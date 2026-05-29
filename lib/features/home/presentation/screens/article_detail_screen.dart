import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../../core/utils/app_error_reporter.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/explore/domain/models/post_model.dart';
import '../../../../features/explore/presentation/providers/post_providers.dart';
import '../../../../theme/style_guide.dart';
import '../../data/repositories/report_repository.dart';
import '../providers/news_provider.dart';
import '../widgets/report_sheet.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final NewsArticleModel? article;
  final String? articleId;

  const ArticleDetailScreen({super.key, this.article, this.articleId})
    : assert(article != null || articleId != null);

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  NewsArticleModel? _article;
  bool _isLoading = false;
  String? _error;
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final article = widget.article;
    if (article != null) {
      _setArticle(article);
    } else {
      _isLiked = false;
      _isBookmarked = false;
      _likesCount = 0;
      _loadArticleById();
    }
    _initializeUserId();
  }

  void _setArticle(NewsArticleModel article) {
    final userId = _userId;
    _article = article;
    _isLiked = userId == null
        ? article.isLiked
        : article.likedBy.contains(userId) || article.isLiked;
    _isBookmarked = userId == null
        ? article.isBookmarked
        : article.bookmarkedBy.contains(userId) || article.isBookmarked;
    _likesCount = article.likesCount;
    // Increment view count silently
    if (article.id.isNotEmpty) {
      ref.read(firestoreRepositoryProvider).incrementViewCount(article.id);
    }
  }

  Future<void> _loadArticleById() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final article = await ref
          .read(firestoreRepositoryProvider)
          .getArticleById(widget.articleId ?? '');
      if (!mounted) return;
      if (article == null) {
        setState(() {
          _isLoading = false;
          _error = 'Article not found.';
        });
        return;
      }
      setState(() {
        _setArticle(article);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to load article',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load this article.';
      });
    }
  }

  Future<void> _initializeUserId() async {
    try {
      final userModel = await ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
      if (!mounted) return;
      final userId = userModel?.uid;
      final article = _article;
      setState(() {
        _userId = userId;
        if (article != null && userId != null) {
          _isLiked = article.likedBy.contains(userId) || article.isLiked;
          _isBookmarked =
              article.bookmarkedBy.contains(userId) || article.isBookmarked;
        }
      });
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to initialize article user',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final article = _article;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark, article),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDefault,
                      ),
                    )
                  : _error != null || article == null
                  ? _buildErrorState(isDark)
                  : _buildBody(article, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom AppBar ─────────────────────────────────────────────────────────

  Widget _buildAppBar(bool isDark, NewsArticleModel? article) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Back button
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
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Startups',
                      style: AppTypography.displaySmallBold.copyWith(
                        fontSize: 17,
                        color: AppColors.primaryDefault,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: 'India',
                      style: AppTypography.displaySmallBold.copyWith(
                        fontSize: 17,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.grayscaleTitleActive,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bookmark
          IconButton(
            onPressed: article == null ? null : _toggleBookmark,
            icon: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 22,
              color: _isBookmarked
                  ? AppColors.primaryDefault
                  : isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          // 3-dots
          IconButton(
            onPressed: article == null ? null : () => _showMenu(article),
            icon: Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(NewsArticleModel article, bool isDark) {
    final isPodcast =
        article.category.toLowerCase() == 'podcast' &&
        article.youtubeVideoId.isNotEmpty;
    final bodyParts = _splitBodyForGallery(article.body);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured media comes first.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: isPodcast
                ? _buildYouTubePlayer(article.youtubeVideoId, isDark)
                : _buildFeaturedImage(article, isDark),
          ),
          // Category tag
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _CategoryPill(label: article.category, isDark: isDark),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Text(
              article.headline,
              style: AppTypography.displayMediumBold.copyWith(
                fontSize: 22,
                height: 1.3,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
          // Description
          if (article.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                article.description,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ),
          // Author row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _buildAuthorRow(article, isDark),
          ),
          // Article body, with gallery embedded in the middle of content.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildMarkdownText(bodyParts.$1, isDark),
          ),
          if (article.imageGallery.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildImageGallery(article.imageGallery, isDark),
            const SizedBox(height: 18),
          ],
          if (bodyParts.$2.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _buildMarkdownText(bodyParts.$2, isDark),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _buildArticleActions(article, isDark),
          ),
          _buildRelatedArticlesSection(article, isDark),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ── Author row ────────────────────────────────────────────────────────────

  Widget _buildAuthorRow(NewsArticleModel article, bool isDark) {
    final timeStr = formatArticleTimestamp(
      article.createdAt,
      fallback: article.timeAgo,
    );

    return Row(
      children: [
        // Source/author avatar
        ClipOval(
          child: SizedBox(
            width: 38,
            height: 38,
            child: _buildLogoWidget(article.sourceLogoAsset, isDark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.sourceName.isEmpty
                    ? 'StartupsIndia'
                    : article.sourceName,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
              Row(
                children: [
                  if (timeStr.isNotEmpty) ...[
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                    const SizedBox(width: 3),
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
                  if (timeStr.isNotEmpty && article.viewCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (article.viewCount > 0) ...[
                    Icon(
                      Icons.visibility_outlined,
                      size: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fmtViews(article.viewCount),
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero image ────────────────────────────────────────────────────────────

  Widget _buildFeaturedImage(NewsArticleModel article, bool isDark) {
    final image = article.featuredImageUrl.isNotEmpty
        ? article.featuredImageUrl
        : article.thumbnailAsset;
    if (image.isEmpty) return const SizedBox.shrink();

    return Hero(
      tag: article.id,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildArticleImage(image, isDark),
        ),
      ),
    );
  }

  // ── YouTube player ────────────────────────────────────────────────────────

  Widget _buildYouTubePlayer(String videoId, bool isDark) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
          'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1',
        ),
      );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: controller),
      ),
    );
  }

  // ── Image gallery ─────────────────────────────────────────────────────────

  Widget _buildImageGallery(List<String> images, bool isDark) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: images.length,
        itemBuilder: (context, i) {
          final url = images[i];
          return GestureDetector(
            onTap: () => _openFullScreenImage(url, images, i),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.grayscaleSecondaryButton,
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildArticleImage(url, isDark),
            ),
          );
        },
      ),
    );
  }

  void _openFullScreenImage(
    String url,
    List<String> allImages,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            _FullScreenGallery(images: allImages, initialIndex: initialIndex),
      ),
    );
  }

  // ── Markdown body ─────────────────────────────────────────────────────────

  (String, String) _splitBodyForGallery(String body) {
    final raw = body.trim();
    if (raw.isEmpty) return ('', '');

    final blocks = raw
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList(growable: false);
    if (blocks.length <= 1) return (raw, '');

    final splitIndex = (blocks.length / 2).ceil();
    return (
      blocks.take(splitIndex).join('\n\n'),
      blocks.skip(splitIndex).join('\n\n'),
    );
  }

  Widget _buildMarkdownText(String content, bool isDark) {
    final fallback = 'This article does not have body text yet.';
    final raw = content.trim().isEmpty ? fallback : content.trim();
    final bodyTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.grayscaleBodyText;
    final headingColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;

    return MarkdownBody(
      data: raw,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: AppTypography.textMedium.copyWith(
          fontSize: 16,
          height: 1.7,
          color: bodyTextColor,
        ),
        h1: AppTypography.displaySmallBold.copyWith(
          fontSize: 22,
          color: headingColor,
        ),
        h2: AppTypography.displaySmallBold.copyWith(
          fontSize: 19,
          color: headingColor,
        ),
        h3: AppTypography.displaySmallBold.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: headingColor,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.primaryDefault, width: 4),
          ),
          color: AppColors.primaryDefault.withValues(alpha: 0.06),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        blockquote: AppTypography.textMedium.copyWith(
          fontSize: 15,
          height: 1.55,
          fontStyle: FontStyle.italic,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.grayscaleTitleActive,
        ),
        strong: AppTypography.textMedium.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: headingColor,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppColors.primaryDefault,
          backgroundColor: AppColors.primaryDefault.withValues(alpha: 0.08),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : AppColors.grayscaleSecondaryButton,
          borderRadius: BorderRadius.circular(8),
        ),
        listBullet: AppTypography.textMedium.copyWith(
          fontSize: 16,
          color: AppColors.primaryDefault,
        ),
        pPadding: const EdgeInsets.only(bottom: 12),
        blockSpacing: 12,
      ),
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────

  Widget _buildArticleActions(NewsArticleModel article, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
              label: _fmtEngagement(_likesCount),
              color: _isLiked ? const Color(0xFFE91E63) : null,
              isDark: isDark,
              onTap: _toggleLike,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: _fmtEngagement(article.commentsCount),
              isDark: isDark,
              onTap: _openComments,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              isDark: isDark,
              onTap: _shareArticle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedArticlesSection(NewsArticleModel article, bool isDark) {
    final latestAsync = ref.watch(latestNewsProvider);
    final category = article.category.toLowerCase();
    final isPodcast = category == 'podcast';
    return latestAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        final related = items
            .where(
              (item) =>
                  item.id != article.id &&
                  item.category.toLowerCase() == category,
            )
            .toList(growable: false);
        final fallback = items
            .where(
              (item) =>
                  item.id != article.id &&
                  (!isPodcast || item.category.toLowerCase() == 'podcast'),
            )
            .take(8)
            .toList(growable: false);
        final visible = (related.isEmpty ? fallback : related).take(8).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  isPodcast ? 'Related Podcasts' : 'Related Articles',
                  style: AppTypography.displaySmallBold.copyWith(
                    fontSize: 18,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 198,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _RelatedArticleCard(
                      article: visible[index],
                      isDark: isDark,
                      imageBuilder: _buildArticleImage,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _toggleLike() async {
    final article = _article;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (article == null) return;
    if (userId == null || userId.isEmpty) {
      showGuestAuthPrompt(
        context,
        title: 'Sign in to like stories',
        message: 'Create an account to like articles and podcasts.',
      );
      return;
    }
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      if (_likesCount < 0) _likesCount = 0;
    });
    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleLike(article.id, userId);
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to like article',
      );
    }
  }

  Future<void> _toggleBookmark() async {
    final article = _article;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (article == null) return;
    if (userId == null || userId.isEmpty) {
      showGuestAuthPrompt(
        context,
        title: 'Sign in to save this',
        message: 'Create an account to bookmark articles and podcasts.',
      );
      return;
    }
    setState(() => _isBookmarked = !_isBookmarked);
    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleBookmark(article.id, userId);
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to bookmark article',
      );
    }
  }

  void _shareArticle() {
    final article = _article;
    if (article == null) return;
    final sourceUrl = article.sourceUrl.trim();
    Share.share(
      '${article.headline}\n\n'
      '${sourceUrl.isNotEmpty ? sourceUrl : 'https://startupsindia.in'}',
    );
  }

  void _openComments() {
    final article = _article;
    if (article == null) return;
    if (FirebaseAuth.instance.currentUser == null) {
      showGuestAuthPrompt(
        context,
        title: 'Sign in to comment',
        message: 'Create an account to join the discussion.',
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ArticleCommentSheet(article: article),
    );
  }

  void _showMenu(NewsArticleModel article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            _MenuOption(
              icon: Icons.copy_rounded,
              label: 'Copy headline',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: article.headline));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Headline copied')),
                );
              },
            ),
            _MenuOption(
              icon: Icons.share_outlined,
              label: 'Share article',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _shareArticle();
              },
            ),
            _MenuOption(
              icon: Icons.flag_outlined,
              label: 'Report article',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                ReportSheet.show(
                  context,
                  title: 'Report article',
                  onSubmit: (reason) => ReportRepository().reportArticle(
                    articleId: article.id,
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

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 52,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Article unavailable.',
              textAlign: TextAlign.center,
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try opening it again from the feed.',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadArticleById,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLogoWidget(String logo, bool isDark) {
    final fallback = Container(
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleSecondaryButton,
      child: Icon(
        Icons.public_rounded,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.grayscaleButtonText,
        size: 18,
      ),
    );
    if (logo.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: logo,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    }
    if (logo.isNotEmpty) {
      return Image.asset(
        logo,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }

  Widget _buildArticleImage(String image, bool isDark) {
    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (_, _) => _imageFallback(isDark),
        errorWidget: (_, _, _) => _imageFallback(isDark),
      );
    }
    if (image.isNotEmpty) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(isDark),
      );
    }
    return _imageFallback(isDark);
  }

  Widget _imageFallback(bool isDark) => Container(
    color: isDark ? AppColors.darkSurface : AppColors.grayscaleSecondaryButton,
    alignment: Alignment.center,
    child: Icon(
      Icons.image_outlined,
      color: isDark
          ? AppColors.darkTextSecondary
          : AppColors.grayscaleButtonText,
      size: 30,
    ),
  );

  String _fmtEngagement(int value) {
    if (value >= 1000) {
      final k = value / 1000;
      return k % 1 == 0
          ? '${k.toStringAsFixed(0)}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  String _fmtViews(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M views';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K views';
    return '$v views';
  }
}

// ── Category pill ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool isDark;

  const _CategoryPill({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textSmall.copyWith(
          color: AppColors.primaryDefault,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Full-screen image gallery ─────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        (isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText);
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: resolvedColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedArticleCard extends StatelessWidget {
  final NewsArticleModel article;
  final bool isDark;
  final Widget Function(String image, bool isDark) imageBuilder;

  const _RelatedArticleCard({
    required this.article,
    required this.isDark,
    required this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final image = article.featuredImageUrl.isNotEmpty
        ? article.featuredImageUrl
        : article.thumbnailAsset;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/article-detail', arguments: article),
      child: SizedBox(
        width: 172,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageBuilder(image, isDark),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 0),
                  child: Text(
                    article.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDefault,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                  child: Text(
                    article.headline,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _current;
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDefault,
                    ),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Page indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _current == i ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _current == i
                          ? AppColors.primaryDefault
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Article comment sheet ─────────────────────────────────────────────────────

class _ArticleCommentSheet extends ConsumerStatefulWidget {
  final NewsArticleModel article;

  const _ArticleCommentSheet({required this.article});

  @override
  ConsumerState<_ArticleCommentSheet> createState() =>
      _ArticleCommentSheetState();
}

class _ArticleCommentSheetState extends ConsumerState<_ArticleCommentSheet> {
  final _controller = TextEditingController();
  bool _posting = false;
  late final Stream<List<CommentModel>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = ref
        .read(postRepositoryProvider)
        .watchArticleComments(widget.article.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _controller.text.trim();
    if (uid == null) {
      showGuestAuthPrompt(
        context,
        title: 'Sign in to comment',
        message: 'Create an account to ask questions and reply to discussions.',
      );
      return;
    }
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final userModel = await ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
      final authorName = userModel?.displayName.isNotEmpty == true
          ? userModel!.displayName
          : userModel?.fullName ?? 'User';
      await ref
          .read(postRepositoryProvider)
          .addArticleComment(
            articleId: widget.article.id,
            userId: uid,
            authorName: authorName,
            avatarUrl: userModel?.avatarUrl ?? '',
            content: text,
          );
      _controller.clear();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.grayscaleWhite;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.grayscaleBodyText;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Comments',
              style: AppTypography.textSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          // Comment list
          SizedBox(
            height: 320,
            child: StreamBuilder<List<CommentModel>>(
              stream: _commentsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDefault,
                      strokeWidth: 2,
                    ),
                  );
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: textSecondary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No comments yet',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to share your thoughts!',
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) =>
                      _SheetCommentTile(comment: comments[i], isDark: isDark),
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.grayscaleLine,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTypography.textSmall.copyWith(
                      color: textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: AppTypography.textSmall.copyWith(
                        color: textSecondary,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : AppColors.grayscaleSecondaryButton,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: _posting
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryDefault,
                            strokeWidth: 2,
                          ),
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDefault,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
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
}

class _SheetCommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isDark;

  const _SheetCommentTile({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.grayscaleTitleActive;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.grayscaleBodyText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.darkSurface
                : AppColors.grayscaleSecondaryButton,
          ),
          child: ClipOval(
            child: comment.avatarUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: comment.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.person_rounded,
                      color: textSecondary,
                      size: 16,
                    ),
                  )
                : Icon(Icons.person_rounded, color: textSecondary, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.authorName,
                style: AppTypography.textSmall.copyWith(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: AppTypography.textSmall.copyWith(
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Menu option ───────────────────────────────────────────────────────────────

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuOption({
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
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
