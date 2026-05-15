import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/domain/models/news_feed_data.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../../../theme/style_guide.dart';

enum _ProfileTab { news, recent, bookmarks }

class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() =>
      _PersonalProfileScreenState();
}

class _PersonalProfileScreenState
    extends ConsumerState<PersonalProfileScreen> {
  late Future<UserModel> _userFuture;
  _ProfileTab _activeTab = _ProfileTab.recent;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<UserModel> _loadUser() async {
    final profile = await ref.read(authRepositoryProvider).getCurrentUserModel();
    return profile ??
        const UserModel(
          uid: 'demo_user',
          displayName: 'Your Name',
          bio: 'Building something great. Follow along the journey.',
          avatarUrl: '',
          websiteUrl: 'https://example.com',
          followersCount: 0,
          followingCount: 0,
          newsCount: 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<UserModel>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.grayscaleWhite,
            body: const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryDefault),
            ),
          );
        }

        final user = snapshot.data!;
        final newsItems = _articlesForUser(user.uid);
        final recentItems = newsItems.reversed.toList(growable: false);

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
            backgroundColor: AppColors.primaryDefault,
            elevation: 2,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header bar ───────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeaderBar(context, isDark)),

              // ── Profile card ─────────────────────────────────────────
              SliverToBoxAdapter(
                  child: _buildProfileCard(context, user, isDark)),

              // ── Pinned tabs ──────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabsDelegate(
                  activeTab: _activeTab,
                  isDark: isDark,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                ),
              ),

              // ── Tab content ──────────────────────────────────────────
              if (_activeTab == _ProfileTab.bookmarks)
                SliverToBoxAdapter(child: _buildBookmarksEmpty(isDark))
              else
                _buildArticlesSliver(
                  _activeTab == _ProfileTab.news ? newsItems : recentItems,
                  isDark,
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  // ── Header bar ────────────────────────────────────────────────────────────

  Widget _buildHeaderBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      child: Row(
        children: [
          Text(
            'Profile',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 22,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(
              Icons.settings_outlined,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard(
      BuildContext context, UserModel user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
          ),
        ),
        child: Column(
          children: [
            // ── Cover gradient + avatar ────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover strip
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDefault
                              .withValues(alpha: isDark ? 0.35 : 0.18),
                          AppColors.primaryDefault
                              .withValues(alpha: isDark ? 0.08 : 0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                // Avatar
                Positioned(
                  bottom: -36,
                  left: 20,
                  child: _Avatar(url: user.avatarUrl, isDark: isDark),
                ),
                // Edit profile mini-button top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit-profile'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                                .withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.grayscaleLine,
                        ),
                      ),
                      child: Text(
                        'Edit profile',
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.grayscaleTitleActive,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Name + role + bio ──────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 46, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName.isEmpty
                              ? 'Your Name'
                              : user.displayName,
                          style: AppTypography.displaySmallBold.copyWith(
                            fontSize: 20,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                          ),
                        ),
                      ),
                      // Role badge
                      if (user.role.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDefault
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatRole(user.role),
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDefault,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (user.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.bio,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.grayscaleBodyText,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Stats row ────────────────────────────────────────
                  Row(
                    children: [
                      _Stat(
                          value: _formatCount(user.followersCount),
                          label: 'Followers',
                          isDark: isDark),
                      _StatDivider(isDark: isDark),
                      _Stat(
                          value: _formatCount(user.followingCount),
                          label: 'Following',
                          isDark: isDark),
                      _StatDivider(isDark: isDark),
                      _Stat(
                          value: user.newsCount.toString(),
                          label: 'Posts',
                          isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Website row ──────────────────────────────────────
                  if (user.websiteUrl.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText),
                        const SizedBox(width: 4),
                        Text(
                          user.websiteUrl
                              .replaceFirst('https://', '')
                              .replaceFirst('http://', ''),
                          style: AppTypography.textSmall.copyWith(
                            fontSize: 12,
                            color: AppColors.primaryDefault,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Articles sliver ───────────────────────────────────────────────────────

  Widget _buildArticlesSliver(List<NewsArticle> items, bool isDark) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Center(
            child: Text(
              'No posts yet.',
              style: AppTypography.textSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => NewsTile(article: items[i]),
    );
  }

  // ── Bookmarks empty state ─────────────────────────────────────────────────

  Widget _buildBookmarksEmpty(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border_rounded,
                color: AppColors.primaryDefault, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the bookmark icon on any article\nto save it here.',
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<NewsArticle> _articlesForUser(String uid) {
    final all = [NewsFeedData.trendingArticle, ...NewsFeedData.latestArticles];
    return all.where((a) => a.authorId == uid).toList(growable: false);
  }

  String _formatRole(String role) {
    if (role.isEmpty) return '';
    return role
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String url;
  final bool isDark;

  const _Avatar({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          width: 3,
        ),
        color: isDark
            ? AppColors.darkBackground
            : AppColors.grayscaleSecondaryButton,
      ),
      child: ClipOval(
        child: url.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => _fallback(),
                errorWidget: (context, url, error) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.primaryDefault.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.primaryDefault,
          size: 36,
        ),
      );
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _Stat(
      {required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.textSmall.copyWith(
              fontSize: 11,
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

class _StatDivider extends StatelessWidget {
  final bool isDark;

  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
    );
  }
}

// ── Pinned tab bar ────────────────────────────────────────────────────────────

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final _ProfileTab activeTab;
  final bool isDark;
  final ValueChanged<_ProfileTab> onTabSelected;

  _TabsDelegate({
    required this.activeTab,
    required this.isDark,
    required this.onTabSelected,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Tab(
            label: 'News',
            active: activeTab == _ProfileTab.news,
            isDark: isDark,
            onTap: () => onTabSelected(_ProfileTab.news),
          ),
          const SizedBox(width: 24),
          _Tab(
            label: 'Recent',
            active: activeTab == _ProfileTab.recent,
            isDark: isDark,
            onTap: () => onTabSelected(_ProfileTab.recent),
          ),
          const SizedBox(width: 24),
          _Tab(
            label: 'Bookmarks',
            active: activeTab == _ProfileTab.bookmarks,
            isDark: isDark,
            onTap: () => onTabSelected(_ProfileTab.bookmarks),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.activeTab != activeTab || old.isDark != isDark;
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _Tab({
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
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active
                  ? (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive)
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleButtonText),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 2.5,
            width: active ? label.length * 7.5 : 0,
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
