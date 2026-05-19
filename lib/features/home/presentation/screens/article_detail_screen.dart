import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../theme/style_guide.dart';
import '../../../explore/data/repositories/mock_source_repository.dart';
import '../../../explore/domain/repositories/source_repository.dart';

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
    } catch (_) {
      // Guest state is allowed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final article = _article;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        surfaceTintColor:
            isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
            size: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: article == null ? null : _showSharePlaceholder,
            icon: Icon(
              Icons.share_outlined,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          IconButton(
            onPressed: article == null ? null : _showMenuPlaceholder,
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
      body: _buildBody(article, isDark),
      bottomNavigationBar:
          article == null ? null : _buildBottomActionBar(article, isDark),
    );
  }

  Widget _buildBody(NewsArticleModel? article, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDefault),
      );
    }

    final error = _error;
    if (error != null || article == null) {
      return _ArticleStateMessage(
        icon: Icons.article_outlined,
        title: error ?? 'Article unavailable.',
        subtitle: 'Try opening it again from the feed.',
        isDark: isDark,
        actionLabel: 'Retry',
        onAction: _loadArticleById,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSourceRow(article, isDark),
            const SizedBox(height: 16),
            _buildHeroImage(article, isDark),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ArticleMetaChip(label: article.category, isDark: isDark),
                _ArticleMetaChip(label: _publishedLabel(article), isDark: isDark),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.headline,
              style: AppTypography.displayMediumBold.copyWith(
                fontSize: 34,
                height: 1.22,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const SizedBox(height: 16),
            ..._buildBodyParagraphs(article, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceRow(NewsArticleModel article, bool isDark) {
    return Row(
      children: [
        _buildSourceLogo(article, isDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.sourceName.isEmpty ? 'Unknown source' : article.sourceName,
                style: AppTypography.textMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                article.timeAgo.isEmpty ? 'Recently' : article.timeAgo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: _isUpdatingFollow ? null : _toggleFollowSource,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDefault,
              foregroundColor: AppColors.grayscaleWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
            ),
            child: _isUpdatingFollow
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.grayscaleWhite,
                    ),
                  )
                : Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: AppTypography.textSmall.copyWith(
                      color: AppColors.grayscaleWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceLogo(NewsArticleModel article, bool isDark) {
    final logo = article.sourceLogoAsset;
    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: logo.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.cover,
                placeholder: (context, url) => _logoFallback(isDark),
                errorWidget: (context, url, error) => _logoFallback(isDark),
              )
            : Image.asset(
                logo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _logoFallback(isDark),
              ),
      ),
    );
  }

  Widget _buildHeroImage(NewsArticleModel article, bool isDark) {
    final image = article.thumbnailAsset;
    return Hero(
      tag: article.id,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: image.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _imageFallback(isDark),
                  errorWidget: (context, url, error) => _imageFallback(isDark),
                )
              : Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _imageFallback(isDark),
                ),
        ),
      ),
    );
  }

  List<Widget> _buildBodyParagraphs(NewsArticleModel article, bool isDark) {
    final fallbackBody =
        'This article does not have body text yet. Add story content when creating or importing posts.';
    final raw = article.body.trim().isEmpty ? fallbackBody : article.body.trim();
    final parts = raw.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return parts
        .map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              paragraph.trim(),
              style: AppTypography.textMedium.copyWith(
                fontSize: 17,
                height: 1.55,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildBottomActionBar(NewsArticleModel article, bool isDark) {
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
                  const SizedBox(width: 6),
                  Text(
                    _formatEngagement(_likesCount),
                    style: AppTypography.textMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 26),
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
                  const SizedBox(width: 6),
                  Text(
                    _formatEngagement(article.commentsCount),
                    style: AppTypography.textMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _toggleBookmark,
              icon: Icon(
                _isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 23,
                color: _isBookmarked
                    ? AppColors.primaryDefault
                    : isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFollowSource() async {
    final article = _article;
    if (article == null) return;

    setState(() => _isUpdatingFollow = true);
    final updated = await _sourceRepository.toggleFollowSource(
      sourceId: _resolvedSourceId(article),
      isFollowing: !_isFollowing,
    );

    if (!mounted) return;
    setState(() {
      _isFollowing = updated;
      _isUpdatingFollow = false;
    });
  }

  String _resolvedSourceId(NewsArticleModel article) {
    if (article.sourceId.trim().isNotEmpty) {
      return article.sourceId;
    }
    return article.sourceName.toLowerCase().replaceAll(' ', '_');
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

  void _showSharePlaceholder() {
    final article = _article;
    if (article == null) return;
    final text = '${article.headline}\n\nRead on StartupsIndia';
    Share.share(text);
  }

  void _showMenuPlaceholder() {
    final article = _article;
    if (article == null) return;
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
              icon: Icons.flag_outlined,
              label: 'Report article',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted. Thank you.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openComments() {
    final article = _article;
    if (article == null) return;
    Navigator.pushNamed(context, '/comments', arguments: article);
  }

  String _formatEngagement(int value) {
    if (value >= 1000) {
      final kValue = value / 1000;
      return kValue % 1 == 0
          ? '${kValue.toStringAsFixed(0)}K'
          : '${kValue.toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  String _publishedLabel(NewsArticleModel article) {
    final createdAt = article.createdAt;
    if (createdAt == null) {
      return article.timeAgo.isEmpty ? 'Recently' : article.timeAgo;
    }
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year}';
  }

  Widget _logoFallback(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleSecondaryButton,
      alignment: Alignment.center,
      child: Icon(
        Icons.public_rounded,
        color: isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText,
        size: 20,
      ),
    );
  }

  Widget _imageFallback(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.grayscaleSecondaryButton,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText,
        size: 30,
      ),
    );
  }
}

class _ArticleMetaChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _ArticleMetaChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.isEmpty ? 'News' : label,
        style: AppTypography.textSmall.copyWith(
          color: AppColors.primaryDefault,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ArticleStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final String actionLabel;
  final VoidCallback onAction;

  const _ArticleStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.displaySmallBold.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                foregroundColor: AppColors.grayscaleWhite,
                elevation: 0,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

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
              style: AppTypography.textMedium.copyWith(
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
