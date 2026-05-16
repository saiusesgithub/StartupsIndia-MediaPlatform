import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/search_text_field.dart';
import '../../../../theme/style_guide.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/presentation/widgets/news_tile.dart';

class BookmarkScreen extends StatefulWidget {
  final List<NewsArticle> bookmarkedArticles;
  final VoidCallback? onGoHome;

  const BookmarkScreen({
    super.key,
    this.bookmarkedArticles = const <NewsArticle>[],
    this.onGoHome,
  });

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';

  List<NewsArticle> get _filteredBookmarks {
    if (_query.trim().isEmpty) {
      return widget.bookmarkedArticles;
    }

    final q = _query.toLowerCase().trim();
    return widget.bookmarkedArticles
        .where((article) {
          return article.headline.toLowerCase().contains(q) ||
              article.category.toLowerCase().contains(q) ||
              article.sourceName.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookmarks = _filteredBookmarks;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bookmark',
                  style: AppTypography.displayMediumBold.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                    height: 1.15,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
              child: SearchTextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: filteredBookmarks.isEmpty
                  ? _BookmarkEmptyState(
                      onGoHome: widget.onGoHome,
                      isDark: isDark,
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredBookmarks.length,
                      itemBuilder: (context, index) {
                        return NewsTile(article: filteredBookmarks[index]);
                      },
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 24,
                        endIndent: 24,
                        color:
                            isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkEmptyState extends StatelessWidget {
  final VoidCallback? onGoHome;
  final bool isDark;

  const _BookmarkEmptyState({this.onGoHome, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 60,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
            const SizedBox(height: 14),
            Text(
              'No saved stories yet',
              style: AppTypography.displaySmallBold.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Save stories from the feed and they will show up here.',
              style: AppTypography.textSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  if (onGoHome != null) {
                    onGoHome!.call();
                    return;
                  }
                  Navigator.pushNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDefault,
                  foregroundColor: AppColors.grayscaleWhite,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Back To Home Feed',
                  style: AppTypography.textSmall.copyWith(
                    color: AppColors.grayscaleWhite,
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
