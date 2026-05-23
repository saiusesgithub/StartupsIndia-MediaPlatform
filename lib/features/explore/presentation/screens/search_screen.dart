import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../../theme/style_guide.dart';
import '../../../community/domain/models/community_model.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/presentation/providers/news_provider.dart';
import '../../../home/presentation/widgets/news_tile.dart';

enum SearchTab { articles, communities }

class SearchScreen extends ConsumerStatefulWidget {
  final SearchTab initialTab;

  const SearchScreen({super.key, this.initialTab = SearchTab.articles});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late SearchTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    ref.read(searchQueryProvider.notifier).setQuery(v);
    setState(() {});
  }

  void _clearQuery() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              focusNode: _focusNode,
              tab: _tab,
              isDark: isDark,
              onChanged: _onQueryChanged,
              onClear: _clearQuery,
            ),
            _TabBar(
              tab: _tab,
              isDark: isDark,
              onChanged: (t) => setState(() => _tab = t),
            ),
            Expanded(
              child: _tab == SearchTab.articles
                  ? _ArticlesBody(
                      query: _controller.text.trim(),
                      isDark: isDark,
                    )
                  : _CommunitiesBody(
                      query: _controller.text.trim().toLowerCase(),
                      isDark: isDark,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final SearchTab tab;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.tab,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkInputBackground
                    : AppColors.grayscaleInputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: AppTypography.textSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: tab == SearchTab.articles
                      ? 'Search articles…'
                      : 'Search communities…',
                  hintStyle: AppTypography.textSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleButtonText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
                          ),
                          onPressed: onClear,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final SearchTab tab;
  final bool isDark;
  final ValueChanged<SearchTab> onChanged;

  const _TabBar({
    required this.tab,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _TabItem(
            label: 'Articles',
            tab: SearchTab.articles,
            currentTab: tab,
            isDark: isDark,
            onTap: onChanged,
          ),
          _TabItem(
            label: 'Communities',
            tab: SearchTab.communities,
            currentTab: tab,
            isDark: isDark,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final SearchTab tab;
  final SearchTab currentTab;
  final bool isDark;
  final ValueChanged<SearchTab> onTap;

  const _TabItem({
    required this.label,
    required this.tab,
    required this.currentTab,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(tab),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                style: AppTypography.textSmall.copyWith(
                  color: isActive
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive)
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleButtonText),
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2.5,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryDefault
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Articles body ──────────────────────────────────────────────────────────────

class _ArticlesBody extends ConsumerWidget {
  final String query;
  final bool isDark;

  const _ArticlesBody({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.isEmpty) {
      return _TrendingSuggestions(isDark: isDark);
    }

    final searchAsync = ref.watch(searchResultProvider);
    return searchAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDefault),
      ),
      error: (_, s) => _EmptyState(
        icon: Icons.error_outline_rounded,
        message: 'Something went wrong',
        isDark: isDark,
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return _EmptyState(
            icon: Icons.article_outlined,
            message: 'No articles found for "$query"',
            isDark: isDark,
          );
        }
        return ListView.builder(
          itemCount: articles.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, i) =>
              NewsTile(article: _toNewsArticle(articles[i])),
        );
      },
    );
  }

  static NewsArticle _toNewsArticle(NewsArticleModel m) => NewsArticle(
        id: m.id,
        authorId: m.authorId,
        category: m.category,
        headline: m.headline,
        sourceName: m.sourceName,
        sourceId: m.sourceId,
        sourceLogoAsset: m.sourceLogoAsset,
        thumbnailAsset: m.featuredImageUrl.trim().isNotEmpty
            ? m.featuredImageUrl.trim()
            : m.thumbnailAsset,
        timeAgo: formatArticleTimestamp(m.createdAt, fallback: m.timeAgo),
        body: m.body,
        likesCount: m.likesCount,
        commentsCount: m.commentsCount,
        isSourceFollowing: m.isSourceFollowing,
        isBookmarked: m.isBookmarked,
        isLiked: m.isLiked,
      );
}

class _TrendingSuggestions extends ConsumerWidget {
  final bool isDark;

  const _TrendingSuggestions({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingNewsProvider);
    final articles = trendingAsync.asData?.value ?? [];

    if (articles.isEmpty) {
      return _EmptyState(
        icon: Icons.search_rounded,
        message: 'Start typing to search articles',
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'TRENDING',
            style: AppTypography.textSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: articles.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, i) =>
                NewsTile(article: _ArticlesBody._toNewsArticle(articles[i])),
          ),
        ),
      ],
    );
  }
}

// ── Communities body ───────────────────────────────────────────────────────────

class _CommunitiesBody extends ConsumerWidget {
  final String query;
  final bool isDark;

  const _CommunitiesBody({required this.query, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commAsync = ref.watch(communitiesProvider);
    final all = commAsync.asData?.value ?? [];

    final filtered = query.isEmpty
        ? all
        : all
            .where((c) =>
                c.name.toLowerCase().contains(query) ||
                c.description.toLowerCase().contains(query))
            .toList();

    if (filtered.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline_rounded,
        message: query.isEmpty
            ? 'No communities yet'
            : 'No communities found for "$query"',
        isDark: isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: filtered.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, i) =>
          _CommunityTile(community: filtered[i], isDark: isDark),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final CommunityModel community;
  final bool isDark;

  const _CommunityTile({required this.community, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        '/community-detail',
        arguments: community.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: community.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  community.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: AppTypography.textSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  if (community.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      community.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmt(community.memberCount),
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.grayscaleTitleActive,
                  ),
                ),
                Text(
                  'members',
                  style: AppTypography.textSmall.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.grayscaleBodyText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Shared empty state ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 52,
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.35)
                : AppColors.grayscaleButtonText.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
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
