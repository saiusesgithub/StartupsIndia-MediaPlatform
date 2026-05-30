import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/presentation/widgets/shimmer_placeholder.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/app_error_reporter.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/news_article.dart';
import '../../../../theme/style_guide.dart';

final tileLikeStateProvider = StateProvider.autoDispose.family<bool, String>((
  ref,
  articleId,
) {
  return false;
});

final tileAuthorProvider = FutureProvider.autoDispose
    .family<UserModel?, String>((ref, authorId) {
      if (authorId.trim().isEmpty) return null;
      return ref.read(firestoreRepositoryProvider).getUserById(authorId);
    });

/// Reusable tile for the 'Latest' news feed section.
/// Matches the Figma design: thumbnail left, category/headline/source right, bookmark icon.
class NewsTile extends ConsumerStatefulWidget {
  final NewsArticle article;
  final VoidCallback? onTap;

  const NewsTile({super.key, required this.article, this.onTap});

  @override
  ConsumerState<NewsTile> createState() => _NewsTileState();
}

class _NewsTileState extends ConsumerState<NewsTile> {
  late bool _isBookmarked;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _isBookmarked = widget.article.isBookmarked;
    ref.read(tileLikeStateProvider(widget.article.id).notifier).state =
        widget.article.isLiked;
    _loadCurrentUserId();
  }

  @override
  void didUpdateWidget(NewsTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.article.id != widget.article.id) {
      _isBookmarked = widget.article.isBookmarked;
      ref.read(tileLikeStateProvider(widget.article.id).notifier).state =
          widget.article.isLiked;
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final userModel = await ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
      if (!mounted) return;
      setState(() {
        _currentUserId = userModel?.uid;
      });
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to initialize news tile user',
      );
      // Ignore and keep guest behavior.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLiked = ref.watch(tileLikeStateProvider(widget.article.id));
    final authorAsync = ref.watch(tileAuthorProvider(widget.article.authorId));
    final authorName = authorAsync.maybeWhen(
      data: (user) {
        final name = user?.displayName.trim() ?? '';
        return name.isEmpty ? widget.article.sourceName : name;
      },
      orElse: () => widget.article.sourceName,
    );

    return GestureDetector(
      onTap: widget.onTap ?? () => _openDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────
            Hero(
              tag: widget.article.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.article.thumbnailAsset.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: widget.article.thumbnailAsset,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ShimmerPlaceholder(width: 96, height: 96),
                        errorWidget: (context, url, error) =>
                            _thumbnailFallback(),
                      )
                    : Image.asset(
                        widget.article.thumbnailAsset,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _thumbnailFallback(),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Text block ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Text(
                    widget.article.category.toUpperCase(),
                    style: AppTypography.textSmall.copyWith(
                      color: AppColors.primaryDefault,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Headline
                  Text(
                    widget.article.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Source row: logo + name + time + bookmark
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: widget.article.sourceLogoAsset.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: widget.article.sourceLogoAsset,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const ShimmerPlaceholder(
                                      width: 20,
                                      height: 20,
                                    ),
                                errorWidget: (context, url, error) =>
                                    _logoFallback(),
                              )
                            : Image.asset(
                                widget.article.sourceLogoAsset,
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _logoFallback(),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          authorName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleButtonText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.article.timeAgo,
                        style: AppTypography.textSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleButtonText,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isLiked
                              ? Colors.redAccent
                              : isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleButtonText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bookmark icon
                      GestureDetector(
                        onTap: _toggleBookmark,
                        child: Icon(
                          _isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: _isBookmarked
                              ? AppColors.primaryDefault
                              : isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleButtonText,
                          size: 20,
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

  Future<void> _toggleBookmark() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      showGuestAuthPrompt(
        context,
        title: 'Sign in to save stories',
        message: 'Create an account to bookmark articles and find them later.',
      );
      return;
    }

    final previous = _isBookmarked;
    setState(() => _isBookmarked = !previous);

    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleBookmark(widget.article.id, userId);
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to bookmark news tile',
      );
      if (!mounted) return;
      setState(() => _isBookmarked = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bookmark. Try again.')),
      );
    }
  }

  Future<void> _toggleLike() async {
    final previous = ref.read(tileLikeStateProvider(widget.article.id));
    ref.read(tileLikeStateProvider(widget.article.id).notifier).state =
        !previous;

    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      ref.read(tileLikeStateProvider(widget.article.id).notifier).state =
          previous;
      if (!mounted) return;
      showGuestAuthPrompt(
        context,
        title: 'Sign in to like stories',
        message:
            'Create an account to react to articles and personalize your feed.',
      );
      return;
    }

    try {
      await ref
          .read(firestoreRepositoryProvider)
          .toggleLike(widget.article.id, userId);
    } catch (error, stackTrace) {
      AppErrorReporter.record(
        error,
        stackTrace,
        reason: 'Failed to like news tile',
      );
      ref.read(tileLikeStateProvider(widget.article.id).notifier).state =
          previous;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like. Try again.')),
      );
    }
  }

  Widget _thumbnailFallback() {
    return Container(
      width: 96,
      height: 96,
      color: AppColors.grayscaleSecondaryButton,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.grayscaleButtonText,
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      width: 20,
      height: 20,
      color: AppColors.grayscaleLine,
      child: const Icon(
        Icons.newspaper,
        size: 12,
        color: AppColors.grayscaleButtonText,
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/article-detail',
      arguments: widget.article.toNewsArticleModel(),
    );
  }
}
