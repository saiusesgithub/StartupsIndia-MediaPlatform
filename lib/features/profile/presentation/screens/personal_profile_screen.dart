import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/domain/models/news_article.dart';
import '../../../home/domain/models/news_feed_data.dart';
import '../../../home/presentation/widgets/news_tile.dart';
import '../../../../theme/style_guide.dart';

enum PersonalProfileTab { news, recent }

class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() =>
      _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends ConsumerState<PersonalProfileScreen> {
  late Future<UserModel> _userFuture;
  PersonalProfileTab _activeTab = PersonalProfileTab.recent;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  Future<UserModel> _loadUser() async {
    final authRepo = ref.read(authRepositoryProvider);
    final profile = await authRepo.getCurrentUserModel();
    return profile ??
        const UserModel(
          uid: 'demo_user',
          displayName: 'Wilson Franci',
          bio:
              'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
          avatarUrl: 'assets/images/thumb_politics.png',
          websiteUrl: 'https://example.com',
          followersCount: 2156,
          followingCount: 567,
          newsCount: 23,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDefault),
          );
        }

        final user = snapshot.data!;
        final newsItems = _articlesForUser(user.uid);
        final recentItems = newsItems.reversed.toList(growable: false);
        final activeItems = _activeTab == PersonalProfileTab.news
            ? newsItems
            : recentItems;

        return Scaffold(
          backgroundColor: AppColors.grayscaleWhite,
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
            backgroundColor: AppColors.primaryDefault,
            elevation: 2,
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.grayscaleWhite,
            ),
          ),
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, user)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileTabsHeaderDelegate(
                    activeTab: _activeTab,
                    onTabSelected: (tab) => setState(() => _activeTab = tab),
                  ),
                ),
                if (activeItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Text(
                        'No posts yet for this profile.',
                        style: AppTypography.textMedium.copyWith(
                          color: AppColors.grayscaleBodyText,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: activeItems.length,
                    itemBuilder: (context, index) {
                      return NewsTile(article: activeItems[index]);
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                'Profile',
                style: AppTypography.displaySmallBold.copyWith(
                  color: AppColors.grayscaleTitleActive,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.grayscaleTitleActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(url: user.avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      value: user.followersCount.toString(),
                      label: 'Followers',
                    ),
                    _StatColumn(
                      value: user.followingCount.toString(),
                      label: 'Following',
                    ),
                    _StatColumn(
                      value: user.newsCount.toString(),
                      label: 'News',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.displayName,
            style: AppTypography.displaySmallBold.copyWith(
              color: AppColors.grayscaleTitleActive,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.bio,
            style: AppTypography.textMedium.copyWith(
              color: AppColors.grayscaleBodyText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/edit-profile'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryDefault,
                      foregroundColor: AppColors.grayscaleWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Edit profile',
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
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryDefault,
                      foregroundColor: AppColors.grayscaleWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Website',
                      style: AppTypography.textMedium.copyWith(
                        color: AppColors.grayscaleWhite,
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

  List<NewsArticle> _articlesForUser(String userId) {
    final all = <NewsArticle>[
      NewsFeedData.trendingArticle,
      ...NewsFeedData.latestArticles,
    ];
    return all
        .where((article) => article.authorId == userId)
        .toList(growable: false);
  }
}

class _ProfileTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final PersonalProfileTab activeTab;
  final ValueChanged<PersonalProfileTab> onTabSelected;

  _ProfileTabsHeaderDelegate({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.grayscaleWhite,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _ProfileTabItem(
            label: 'News',
            active: activeTab == PersonalProfileTab.news,
            onTap: () => onTabSelected(PersonalProfileTab.news),
          ),
          const SizedBox(width: 20),
          _ProfileTabItem(
            label: 'Recent',
            active: activeTab == PersonalProfileTab.recent,
            onTap: () => onTabSelected(PersonalProfileTab.recent),
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
  bool shouldRebuild(covariant _ProfileTabsHeaderDelegate oldDelegate) {
    return oldDelegate.activeTab != activeTab;
  }
}

class _ProfileTabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ProfileTabItem({
    required this.label,
    required this.active,
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
                  ? AppColors.grayscaleTitleActive
                  : AppColors.grayscaleButtonText,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 170),
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

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.textMedium.copyWith(
            color: AppColors.grayscaleTitleActive,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.textMedium.copyWith(
            color: AppColors.grayscaleBodyText,
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String url;

  const _UserAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 90,
        height: 90,
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
        Icons.person_rounded,
        color: AppColors.grayscaleButtonText,
        size: 32,
      ),
    );
  }
}
