import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../data/repositories/mock_source_repository.dart';
import '../../domain/models/source_profile_model.dart';
import '../../domain/repositories/source_repository.dart';

enum SourceProfileTab { news, recent }

class SourceProfileScreen extends StatefulWidget {
  final SourceProfileModel source;
  final SourceRepository? sourceRepository;

  const SourceProfileScreen({
    super.key,
    required this.source,
    this.sourceRepository,
  });

  @override
  State<SourceProfileScreen> createState() => _SourceProfileScreenState();
}

class _SourceProfileScreenState extends State<SourceProfileScreen> {
  late final SourceRepository _sourceRepository;
  late bool _isFollowing;
  bool _isUpdatingFollow = false;
  SourceProfileTab _activeTab = SourceProfileTab.recent;

  List<NewsArticle> get _activeArticles {
    return _activeTab == SourceProfileTab.news
        ? widget.source.newsArticles
        : widget.source.recentArticles;
  }

  @override
  void initState() {
    super.initState();
    _sourceRepository = widget.sourceRepository ?? MockSourceRepository();
    _isFollowing = widget.source.isFollowing;
  }

  @override
  Widget build(BuildContext context) {
    final articles = _activeArticles;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      body: SafeArea(
        child: CustomScrollView(
          cacheExtent: 900,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, isDark)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SourceTabsHeaderDelegate(
                activeTab: _activeTab,
                isDark: isDark,
                onTabSelected: (tab) => setState(() => _activeTab = tab),
              ),
            ),
            SliverList.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return NewsTile(article: articles[index]);
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                  size: 20,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu action coming soon')),
                  );
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SourceAvatar(url: widget.source.avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatColumn(
                      value: _formatCompactNumber(widget.source.followersCount),
                      label: 'Followers',
                      isDark: isDark,
                    ),
                    _StatColumn(
                      value: _formatCompactNumber(widget.source.followingCount),
                      label: 'Following',
                      isDark: isDark,
                    ),
                    _StatColumn(
                      value: _formatCompactNumber(widget.source.newsCount),
                      label: 'News',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.source.name,
            style: AppTypography.textMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.source.bio,
            style: AppTypography.textMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isUpdatingFollow ? null : _handleToggleFollow,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryDefault,
                      foregroundColor: AppColors.grayscaleWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUpdatingFollow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.grayscaleWhite,
                            ),
                          )
                        : Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: AppTypography.textMedium.copyWith(
                              color: AppColors.grayscaleWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Open website: ${widget.source.websiteUrl}',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Website',
                      style: AppTypography.textMedium.copyWith(
                        color: AppColors.primaryDefault,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleFollow() async {
    setState(() => _isUpdatingFollow = true);

    final updated = await _sourceRepository.toggleFollowSource(
      sourceId: widget.source.id,
      isFollowing: !_isFollowing,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isFollowing = updated;
      _isUpdatingFollow = false;
    });
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }
}

class _SourceAvatar extends StatelessWidget {
  final String url;

  const _SourceAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 84,
        height: 84,
        child: url.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : Image.asset(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.grayscaleSecondaryButton,
      alignment: Alignment.center,
      child: const Icon(
        Icons.public_rounded,
        color: AppColors.grayscaleButtonText,
        size: 26,
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.textMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.textMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
          ),
        ),
      ],
    );
  }
}

class _SourceTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final SourceProfileTab activeTab;
  final ValueChanged<SourceProfileTab> onTabSelected;
  final bool isDark;

  _SourceTabsHeaderDelegate({
    required this.activeTab,
    required this.onTabSelected,
    required this.isDark,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.grayscaleWhite,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _TabItem(
            label: 'News',
            active: activeTab == SourceProfileTab.news,
            isDark: isDark,
            onTap: () => onTabSelected(SourceProfileTab.news),
          ),
          const SizedBox(width: 22),
          _TabItem(
            label: 'Recent',
            active: activeTab == SourceProfileTab.recent,
            isDark: isDark,
            onTap: () => onTabSelected(SourceProfileTab.recent),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _SourceTabsHeaderDelegate oldDelegate) {
    return oldDelegate.activeTab != activeTab || oldDelegate.isDark != isDark;
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.textMedium.copyWith(
              color: active
                  ? (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleButtonText),
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 2.5,
            decoration: BoxDecoration(
              color: active ? AppColors.primaryDefault : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}
