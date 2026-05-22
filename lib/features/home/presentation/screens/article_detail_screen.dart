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
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../theme/style_guide.dart';
import '../../../explore/data/repositories/mock_source_repository.dart';
import '../../../explore/domain/repositories/source_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../widgets/report_sheet.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final NewsArticleModel? article;
  final String? articleId;
  final SourceRepository? sourceRepository;

  const ArticleDetailScreen({
    super.key,
    this.article,
    this.articleId,
    this.sourceRepository,
  }) : assert(article != null || articleId != null);

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  late final SourceRepository _sourceRepository;

  NewsArticleModel? _article;
  bool _isLoading = false;
  String? _error;
  late bool _isFollowing;
  late bool _isLiked;
  late bool _isBookmarked;
  late int _likesCount;
  bool _isUpdatingFollow = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _sourceRepository = widget.sourceRepository ?? MockSourceRepository();
    final article = widget.article;
    if (article != null) {
      _setArticle(article);
    } else {
      _isFollowing = false;
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
    _isFollowing = article.isSourceFollowing;
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load this article.';
      });
    }
  }

  Future<void> _initializeUserId() async {
    try {
      final userModel =
          await ref.read(authRepositoryProvider).getCurrentUserModel();
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final article = _article;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
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
      bottomNavigationBar:
          _article == null ? null : _buildBottomBar(_article!, isDark),
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
          // Logo (centered)
          Expanded(
            child: Center(
              child: Image.asset(
                isDark
                    ? 'assets/startupsindia/logo_dark.png'
                    : 'assets/startupsindia/logo_light.png',
                height: 22,
                fit: BoxFit.contain,
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
    final isPodcast = article.category.toLowerCase() == 'podcast' &&
        article.youtubeVideoId.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          // Hero media: YouTube player OR thumbnail image
          isPodcast
              ? _buildYouTubePlayer(article.youtubeVideoId, isDark)
              : _buildHeroImage(article, isDark),
          // Image gallery (small images)
          if (article.imageGallery.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImageGallery(article.imageGallery, isDark),
          ],
          // Article body (markdown)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: _buildMarkdownBody(article, isDark),
          ),
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
                article.sourceName.isEmpty ? 'StartupsIndia' : article.sourceName,
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
        // Follow button
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: _isUpdatingFollow ? null : _toggleFollowSource,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDefault,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              elevation: 0,
            ),
            child: _isUpdatingFollow
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Hero image ────────────────────────────────────────────────────────────

  Widget _buildHeroImage(NewsArticleModel article, bool isDark) {
    final image = article.thumbnailAsset;
    if (image.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Hero(
        tag: article.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: image.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _imageFallback(isDark),
                    errorWidget: (_, _, _) => _imageFallback(isDark),
                  )
                : Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imageFallback(isDark),
                  ),
          ),
        ),
      ),
    );
  }

  // ── YouTube player ────────────────────────────────────────────────────────

  Widget _buildYouTubePlayer(String videoId, bool isDark) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1'),
      );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: WebViewWidget(controller: controller),
        ),
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
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.grayscaleSecondaryButton,
                ),
                errorWidget: (_, _, _) => Icon(
                  Icons.broken_image_outlined,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleButtonText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFullScreenImage(
      String url, List<String> allImages, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenGallery(
          images: allImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // ── Markdown body ─────────────────────────────────────────────────────────

  Widget _buildMarkdownBody(NewsArticleModel article, bool isDark) {
    final fallback =
        'This article does not have body text yet.';
    final raw = article.body.trim().isEmpty ? fallback : article.body.trim();

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
            left: BorderSide(
              color: AppColors.primaryDefault,
              width: 4,
            ),
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

  Widget _buildBottomBar(NewsArticleModel article, bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.grayscaleLine.withValues(alpha: 0.8),
            ),
          ),
        ),
        child: Row(
          children: [
            // Like
            GestureDetector(
              onTap: _toggleLike,
              child: Row(
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                    size: 22,
                    color: _isLiked
                        ? const Color(0xFFE91E63)
                        : isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _fmtEngagement(_likesCount),
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
            const SizedBox(width: 22),
            // Comment
            GestureDetector(
              onTap: _openComments,
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _fmtEngagement(article.commentsCount),
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
            const SizedBox(width: 22),
            // Share
            GestureDetector(
              onTap: _shareArticle,
              child: Row(
                children: [
                  Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Share',
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
            const Spacer(),
            // Comment input shortcut
            GestureDetector(
              onTap: _openComments,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.grayscaleSecondaryButton,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.grayscaleLine,
                  ),
                ),
                child: Text(
                  'Add comment…',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleButtonText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _toggleFollowSource() async {
    final article = _article;
    if (article == null) return;
    setState(() => _isUpdatingFollow = true);
    final updated = await _sourceRepository.toggleFollowSource(
      sourceId: article.sourceId.trim().isEmpty
          ? article.sourceName.toLowerCase().replaceAll(' ', '_')
          : article.sourceId,
      isFollowing: !_isFollowing,
    );
    if (!mounted) return;
    setState(() {
      _isFollowing = updated;
      _isUpdatingFollow = false;
    });
  }

  Future<void> _toggleLike() async {
    final article = _article;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (article == null || userId == null || userId.isEmpty) return;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      if (_likesCount < 0) _likesCount = 0;
    });
    try {
      await ref.read(firestoreRepositoryProvider).toggleLike(article.id, userId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLiked = !_isLiked;
        _likesCount += _isLiked ? 1 : -1;
        if (_likesCount < 0) _likesCount = 0;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final article = _article;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (article == null || userId == null || userId.isEmpty) return;
    setState(() => _isBookmarked = !_isBookmarked);
    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleBookmark(article.id, userId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBookmarked = !_isBookmarked);
    }
  }

  void _shareArticle() {
    final article = _article;
    if (article == null) return;
    Share.share('${article.headline}\n\nRead on StartupsIndia');
  }

  void _openComments() {
    final article = _article;
    if (article == null) return;
    Navigator.pushNamed(context, '/comments', arguments: article);
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

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

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
