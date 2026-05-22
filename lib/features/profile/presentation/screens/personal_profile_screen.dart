import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/news_article_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/utils/time_format_helper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../explore/data/repositories/post_repository.dart';
import '../../../explore/domain/models/post_model.dart';

enum _Tab { overview, activity, groups, bookmarks }

final profileSavedArticlesProvider =
    StreamProvider.autoDispose<List<NewsArticleModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<NewsArticleModel>[]);
  return ref.watch(firestoreRepositoryProvider).getBookmarkedArticles(user.uid);
});

final profileLikedArticlesProvider =
    StreamProvider.autoDispose<List<NewsArticleModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<NewsArticleModel>[]);
  return ref.watch(firestoreRepositoryProvider).getLikedArticles(user.uid);
});

final profileSavedVideosProvider =
    StreamProvider.autoDispose<List<PostModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(<PostModel>[]);
  return PostRepository().getBookmarkedPosts(user.uid);
});

class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() =>
      _PersonalProfileScreenState();
}

class _PersonalProfileScreenState
    extends ConsumerState<PersonalProfileScreen> {
  late Future<UserModel?> _userFuture;
  _Tab _activeTab = _Tab.overview;

  @override
  void initState() {
    super.initState();
    _userFuture = ref.read(authRepositoryProvider).getCurrentUserModel();
  }

  String _handle(UserModel? user) {
    final username = user?.username.trim() ?? '';
    if (username.isNotEmpty) return username;

    final email = (user?.email.isNotEmpty == true)
        ? user!.email
        : FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) return 'you';
    return email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7);

    if (FirebaseAuth.instance.currentUser == null) {
      return GuestProfileScreen(isDark: isDark);
    }

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryDefault)),
          );
        }

        final user = snapshot.data ??
            const UserModel(
              uid: '',
              displayName: 'Your Name',
              bio: '',
              avatarUrl: '',
              websiteUrl: '',
              followersCount: 0,
              followingCount: 0,
              newsCount: 0,
            );

        return Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: _HeaderBar(user: user, isDark: isDark)),
              SliverToBoxAdapter(
                  child: _ProfileCard(
                user: user,
                handle: _handle(user),
                isDark: isDark,
                onEditProfile: _openEditProfile,
              )),
              SliverToBoxAdapter(child: _ProBanner(isDark: isDark)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabsDelegate(
                  activeTab: _activeTab,
                  isDark: isDark,
                  onTabSelected: (t) => setState(() => _activeTab = t),
                ),
              ),
              ..._tabContent(_activeTab, user, isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _tabContent(_Tab tab, UserModel user, bool isDark) {
    switch (tab) {
      case _Tab.overview:
        return [_OverviewSliver(user: user, isDark: isDark)];
      case _Tab.activity:
        return [_ActivitySliver(isDark: isDark)];
      case _Tab.groups:
        return [_ProfileCommunitiesSliver(isDark: isDark)];
      case _Tab.bookmarks:
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Text(
                'Saved Articles',
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
            ),
          ),
          _ArticleListSliver(
            articlesAsync: ref.watch(profileSavedArticlesProvider),
            isDark: isDark,
            emptyIcon: Icons.bookmark_border_rounded,
            emptyTitle: 'No saved articles',
            emptySubtitle:
                'Tap the bookmark on any article to save it here.',
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
              child: Text(
                'Saved Videos',
                style: AppTypography.displaySmallBold.copyWith(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
            ),
          ),
          _SavedVideosSliver(isDark: isDark),
        ];
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.pushNamed(context, '/edit-profile');
    if (!mounted) return;
    setState(() {
      _userFuture = ref.read(authRepositoryProvider).getCurrentUserModel();
    });
  }
}

// ── Communities tab ───────────────────────────────────────────────────────────

class _ProfileCommunitiesSliver extends ConsumerWidget {
  final bool isDark;
  const _ProfileCommunitiesSliver({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(communitiesProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);

    final all = communitiesAsync.asData?.value ?? [];
    final memberships = membershipsAsync.asData?.value ?? {};
    final joined = all.where((c) => memberships.contains(c.id)).toList();

    if (communitiesAsync.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryDefault),
          ),
        ),
      );
    }

    if (joined.isEmpty) {
      return SliverToBoxAdapter(
        child: _EmptyState(
          isDark: isDark,
          icon: Icons.people_outline_rounded,
          title: 'No communities yet',
          subtitle: 'Join a community to see it here.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final c = joined[i];
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/community-detail',
                arguments: c.id,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
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
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          c.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.grayscaleTitleActive,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmtCount(c.memberCount)} members',
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.grayscaleBodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleButtonText,
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: joined.length,
        ),
      ),
    );
  }

  String _fmtCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

// ── Saved Videos tab ──────────────────────────────────────────────────────────

class _SavedVideosSliver extends ConsumerWidget {
  final bool isDark;

  const _SavedVideosSliver({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(profileSavedVideosProvider);

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: videosAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        data: (videos) {
          if (videos.isEmpty) {
            return SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.play_circle_outline_rounded,
                      size: 48,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleButtonText),
                  const SizedBox(height: 12),
                  Text(
                    'No saved videos',
                    style: AppTypography.textMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bookmark videos in the Explore feed to find them here.',
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
          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _VideoThumb(post: videos[i]),
              childCount: videos.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 9 / 16,
            ),
          );
        },
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final PostModel post;

  const _VideoThumb({required this.post});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          post.thumbnailUrl.startsWith('http')
              ? Image.network(post.thumbnailUrl, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: AppColors.darkSurface))
              : Container(color: AppColors.darkSurface),
          const Positioned(
            bottom: 6,
            left: 6,
            child: Icon(Icons.play_circle_filled_rounded,
                color: Colors.white70, size: 28),
          ),
          if (post.headline.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  post.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArticleListSliver extends StatelessWidget {
  final AsyncValue<List<NewsArticleModel>> articlesAsync;
  final bool isDark;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _ArticleListSliver({
    required this.articlesAsync,
    required this.isDark,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return articlesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryDefault),
          ),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: _EmptyState(
          isDark: isDark,
          icon: Icons.error_outline_rounded,
          title: 'Could not load articles',
          subtitle: 'Pull back later or check your connection.',
        ),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              isDark: isDark,
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index.isOdd) {
                return Divider(
                  height: 1,
                  indent: 24,
                  endIndent: 24,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.grayscaleLine,
                );
              }

              final article = _toNewsArticle(articles[index ~/ 2]);
              return NewsTile(article: article);
            },
            childCount: articles.length * 2 - 1,
          ),
        );
      },
    );
  }

  NewsArticle _toNewsArticle(NewsArticleModel model) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return NewsArticle(
      id: model.id,
      authorId: model.authorId,
      category: model.category,
      headline: model.headline,
      sourceName: model.sourceName,
      sourceId: model.sourceId,
      sourceLogoAsset: model.sourceLogoAsset,
      thumbnailAsset: model.thumbnailAsset,
      timeAgo: formatArticleTimestamp(model.createdAt, fallback: model.timeAgo),
      body: model.body,
      likesCount: model.likesCount,
      commentsCount: model.commentsCount,
      isSourceFollowing: model.isSourceFollowing,
      isBookmarked:
          model.isBookmarked || model.bookmarkedBy.contains(currentUserId),
      isLiked: model.isLiked || model.likedBy.contains(currentUserId),
    );
  }
}

// ── Header bar ────────────────────────────────────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const _HeaderBar({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
        child: Row(
          children: [
            Text(
              'My Profile',
              style: AppTypography.displaySmallBold.copyWith(
                fontSize: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/notifications'),
              icon: Icon(Icons.notifications_none_rounded,
                  color: iconColor, size: 24),
              tooltip: 'Notifications',
            ),
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/settings'),
              icon: Icon(Icons.settings_outlined,
                  color: iconColor, size: 22),
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserModel user;
  final String handle;
  final bool isDark;
  final VoidCallback onEditProfile;

  const _ProfileCard({
    required this.user,
    required this.handle,
    required this.isDark,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
        ),
        child: Column(
          children: [
            // ── Cover + avatar stack ──────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDefault
                              .withValues(alpha: isDark ? 0.40 : 0.22),
                          const Color(0xFF1A0A2E)
                              .withValues(alpha: isDark ? 0.70 : 0.30),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: _Avatar(url: user.avatarUrl, isDark: isDark),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground.withValues(alpha: 0.7)
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

            // ── Name / handle / role / bio / stats / website ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                            const SizedBox(height: 2),
                            Text(
                              '@$handle',
                              style: AppTypography.textSmall.copyWith(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleBodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.role.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDefault
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _fmtRole(user.role),
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDefault,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
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
                  if (user.interests.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests
                          .map(
                            (interest) => _InterestChip(
                              label: _fmtRole(interest),
                              isDark: isDark,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Location · Joined date · Website
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (_location(user).isNotEmpty)
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: _location(user),
                          isDark: isDark,
                        ),
                      _MetaChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Joined ${_joinedDate()}',
                        isDark: isDark,
                      ),
                      if (user.websiteUrl.isNotEmpty)
                        _MetaChip(
                          icon: Icons.link_rounded,
                          label: user.websiteUrl
                              .replaceFirst(RegExp(r'https?://'), ''),
                          isDark: isDark,
                          isLink: true,
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

  static String _fmtRole(String role) => role
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  static String _location(UserModel user) =>
      user.roleDetails['location']?.toString().trim() ?? '';

  static String _joinedDate() {
    final created =
        FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (created == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[created.month - 1]} ${created.year}';
  }
}

// ── Pro upgrade banner ────────────────────────────────────────────────────────

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _InterestChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryDefault.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryDefault.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.textSmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDefault,
        ),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final bool isDark;

  const _ProBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryDefault
                  .withValues(alpha: isDark ? 0.18 : 0.08),
              const Color(0xFFFF6B35)
                  .withValues(alpha: isDark ? 0.10 : 0.04),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primaryDefault.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryDefault.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.primaryDefault, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StartupsIndia Pro',
                    style: AppTypography.displaySmallBold.copyWith(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                  Text(
                    'Analytics, priority features & more',
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/pro'),
              child: Text(
                'Upgrade Now →',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDefault,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned 5-icon tab bar ─────────────────────────────────────────────────────

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final _Tab activeTab;
  final bool isDark;
  final ValueChanged<_Tab> onTabSelected;

  _TabsDelegate({
    required this.activeTab,
    required this.isDark,
    required this.onTabSelected,
  });

  static final _items = [
    (tab: _Tab.overview, icon: Icons.person_outline_rounded, label: 'Overview'),
    (tab: _Tab.activity, icon: Icons.timeline_rounded, label: 'Activity'),
    (tab: _Tab.groups, icon: Icons.people_outline_rounded, label: 'Groups'),
    (tab: _Tab.bookmarks, icon: Icons.bookmark_border_rounded, label: 'Bookmarks'),
  ];

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg =
        isDark ? AppColors.darkBackground : const Color(0xFFF5F5F7);
    return Container(
      color: bg,
      child: Row(
        children: _items
            .map((item) => Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(item.tab),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: activeTab == item.tab
                                ? AppColors.primaryDefault
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: activeTab == item.tab
                                ? AppColors.primaryDefault
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.grayscaleButtonText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 9,
                              fontWeight: activeTab == item.tab
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: activeTab == item.tab
                                  ? AppColors.primaryDefault
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.grayscaleButtonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.activeTab != activeTab || old.isDark != isDark;
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewSliver extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const _OverviewSliver({required this.user, required this.isDark});

  static const _roleDetailLabels = <String, Map<String, String>>{
    'student': {
      'collegeName': 'College',
      'degreeCourse': 'Degree',
      'year': 'Year',
      'branch': 'Branch',
      'skills': 'Skills',
      'lookingFor': 'Looking For',
    },
    'founder': {
      'startupName': 'Startup',
      'startupStage': 'Stage',
      'industry': 'Industry',
      'startupDescription': 'About',
      'startupLocation': 'Location',
      'teamSize': 'Team Size',
      'businessNeeds': 'Looking For',
    },
    'mentor': {
      'profession': 'Designation',
      'company': 'Company',
      'expertise': 'Expertise',
      'yearsExperience': 'Experience',
      'industry': 'Industry',
      'mentorshipArea': 'Mentors In',
      'availability': 'Availability',
    },
    'investor': {
      'investorType': 'Type',
      'firmName': 'Firm',
      'investmentRange': 'Ticket Size',
      'preferredIndustries': 'Industries',
      'preferredStage': 'Stage',
      'portfolioCompanies': 'Portfolio',
    },
    'college': {
      'collegeName': 'College',
      'collegeType': 'Type',
      'cityState': 'Location',
      'contactPersonName': 'Contact',
      'designation': 'Designation',
      'numberOfStudents': 'Students',
      'interestedIn': 'Interested In',
    },
    'startup_enthusiast': {
      'interestArea': 'Interests',
      'lookingFor': 'Looking For',
    },
  };

  @override
  Widget build(BuildContext context) {
    final labelMap = _roleDetailLabels[user.role] ?? {};
    final roleRows = labelMap.entries
        .where((e) =>
            user.roleDetails[e.key]?.toString().trim().isNotEmpty == true)
        .toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (user.bio.trim().isNotEmpty) ...[
            _SectionHeader(title: 'About Me', isDark: isDark),
            const SizedBox(height: 8),
            _InfoCard(
              isDark: isDark,
              child: Text(
                user.bio.trim(),
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  height: 1.55,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.grayscaleBodyText,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (roleRows.isNotEmpty) ...[
            _SectionHeader(
              title: _roleSectionTitle(user.role),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _InfoCard(
              isDark: isDark,
              child: Column(
                children: [
                  for (var i = 0; i < roleRows.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.grayscaleLine,
                      ),
                    _DetailRow(
                      label: roleRows[i].value,
                      value:
                          user.roleDetails[roleRows[i].key]!.toString().trim(),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionHeader(title: 'Achievements', isDark: isDark),
          const SizedBox(height: 8),
          _AchievementsRow(role: user.role, isDark: isDark),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  static String _roleSectionTitle(String role) => switch (role) {
        'student' => 'Education',
        'founder' => 'Startup',
        'mentor' => 'Mentorship',
        'investor' => 'Investment',
        'college' => 'College Info',
        _ => 'Details',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.displaySmallBold.copyWith(
        fontSize: 15,
        color: isDark
            ? AppColors.darkTextPrimary
            : AppColors.grayscaleTitleActive,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _InfoCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _DetailRow(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.textSmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.grayscaleTitleActive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity tab ──────────────────────────────────────────────────────────────

class _ActivitySliver extends StatelessWidget {
  final bool isDark;
  const _ActivitySliver({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _EmptyState(
        isDark: isDark,
        icon: Icons.timeline_rounded,
        title: 'No activity yet',
        subtitle: 'Your likes, comments, and community activity will appear here.',
      ),
    );
  }
}

// ── Achievements row (used inside Overview) ───────────────────────────────────

class _AchievementsRow extends StatelessWidget {
  final String role;
  final bool isDark;

  const _AchievementsRow({required this.role, required this.isDark});

  static const _byRole = <String, List<(IconData, Color, String)>>{
    'student': [
      (Icons.school_rounded, Color(0xFF2196F3), 'Learner'),
      (Icons.bolt_rounded, Color(0xFF4CAF50), 'Early Adopter'),
      (Icons.star_rounded, Color(0xFFFFC107), 'Go-Getter'),
    ],
    'founder': [
      (Icons.rocket_launch_rounded, Color(0xFFFF5722), 'Builder'),
      (Icons.emoji_events_rounded, Color(0xFFFFC107), 'Visionary'),
      (Icons.bolt_rounded, Color(0xFF4CAF50), 'Early Adopter'),
    ],
    'mentor': [
      (Icons.workspace_premium_rounded, Color(0xFFFFC107), 'Top Mentor'),
      (Icons.lightbulb_rounded, Color(0xFF9C27B0), 'Thought Leader'),
      (Icons.bolt_rounded, Color(0xFF4CAF50), 'Early Adopter'),
    ],
    'investor': [
      (Icons.trending_up_rounded, Color(0xFF4CAF50), 'Deal Maker'),
      (Icons.emoji_events_rounded, Color(0xFFFFC107), 'Backer'),
      (Icons.bolt_rounded, Color(0xFF2196F3), 'Early Adopter'),
    ],
  };

  static const _default = [
    (Icons.emoji_events_rounded, Color(0xFFFFC107), 'Contributor'),
    (Icons.bolt_rounded, Color(0xFF4CAF50), 'Early Adopter'),
    (Icons.auto_stories_rounded, Color(0xFF2196F3), 'Active Learner'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _byRole[role] ?? _default;
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.grayscaleLine),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: items[i].$2.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(items[i].$1, color: items[i].$2, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    items[i].$3,
                    textAlign: TextAlign.center,
                    style: AppTypography.textSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.grayscaleTitleActive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryDefault.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, color: AppColors.primaryDefault, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 15,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
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
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String url;
  final bool isDark;

  const _Avatar({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
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
        child: const Icon(Icons.person_rounded,
            color: AppColors.primaryDefault, size: 38),
      );
}

// ── Meta chip (location / joined / website) ───────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isLink;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLink
        ? AppColors.primaryDefault
        : (isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textSmall.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
