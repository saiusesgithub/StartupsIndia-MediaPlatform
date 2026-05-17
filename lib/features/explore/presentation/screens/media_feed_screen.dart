import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/providers/user_topics_provider.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/media_post.dart';
import '../../../home/presentation/providers/news_provider.dart';

// ── Tab definitions ────────────────────────────────────────────────────────────

const _tabs = [
  'For You',
  'Trending',
  'Stories',
  'Funding',
  'Startups',
  'Founders',
  'Women',
  'Business',
];

const _tabCategoryMap = {
  'For You': '',
  'Trending': '',
  'Stories': 'stories',
  'Funding': 'funding',
  'Startups': 'startups',
  'Founders': 'founders',
  'Women': 'women',
  'Business': 'business',
};

// ── Gradient fallbacks (one per card colour index) ────────────────────────────

const _cardColors = [
  Color(0xFF1A0A2E),
  Color(0xFF0A1628),
  Color(0xFF0D2137),
  Color(0xFF1C0A0A),
  Color(0xFF0A1C0A),
  Color(0xFF1A1A0A),
  Color(0xFF12151A),
  Color(0xFF1A120F),
];

// ── Root screen ────────────────────────────────────────────────────────────────

class MediaFeedScreen extends ConsumerStatefulWidget {
  const MediaFeedScreen({super.key});

  @override
  ConsumerState<MediaFeedScreen> createState() => _MediaFeedScreenState();
}

class _MediaFeedScreenState extends ConsumerState<MediaFeedScreen> {
  int _tabIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<MediaPost> _buildFeed(
    List<NewsArticleModel> all,
    List<NewsArticleModel> trending,
    List<String> followedTopics,
  ) {
    final tab = _tabs[_tabIndex];

    List<NewsArticleModel> source;
    if (tab == 'Trending') {
      source = trending.isNotEmpty ? trending : all;
    } else {
      source = all;
    }

    final posts = source
        .asMap()
        .entries
        .map((e) => _toMediaPost(e.value, e.key))
        .toList();

    if (tab == 'For You') {
      if (followedTopics.isEmpty) return posts;
      final followed = posts
          .where((p) =>
              followedTopics.contains(p.category.toLowerCase()))
          .toList();
      final rest = posts
          .where((p) =>
              !followedTopics.contains(p.category.toLowerCase()))
          .toList();
      return [...followed, ...rest];
    }

    final filter = _tabCategoryMap[tab] ?? '';
    if (filter.isEmpty) return posts;
    final filtered = posts
        .where((p) => p.category.toLowerCase().contains(filter))
        .toList();
    return filtered.isNotEmpty ? filtered : posts;
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(latestNewsProvider);
    final trendingAsync = ref.watch(trendingNewsProvider);
    final topicsAsync = ref.watch(userTopicsProvider);

    final all = allAsync.asData?.value ?? [];
    final trending = trendingAsync.asData?.value ?? [];
    final followedTopics = topicsAsync.asData?.value ?? [];

    final posts = _buildFeed(all, trending, followedTopics);
    final isGuest = FirebaseAuth.instance.currentUser == null;
    // Guests can swipe through 2 cards; 3rd slot is the sign-up gate.
    final guestLimit = 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Swipe feed ──────────────────────────────────────────────
          if (posts.isEmpty)
            const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryDefault),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: isGuest ? guestLimit + 1 : posts.length,
              itemBuilder: (context, i) {
                if (isGuest && i >= guestLimit) {
                  return const GuestFeedGate();
                }
                return _MediaCard(post: posts[i]);
              },
            ),

          // ── Header overlay (logo + search + tabs) ───────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(
              tabIndex: _tabIndex,
              onTabChanged: (i) {
                setState(() => _tabIndex = i);
                _pageController.jumpToPage(0);
              },
            ),
          ),
        ],
      ),
    );
  }

  static MediaPost _toMediaPost(NewsArticleModel article, int index) {
    final words = article.body.trim().split(RegExp(r'\s+'));
    final readTime = (words.length / 200).ceil().clamp(1, 30);
    return MediaPost(
      id: article.id,
      authorId: article.authorId,
      authorName: article.sourceName,
      authorRole: article.category,
      authorAvatarUrl: article.sourceLogoAsset,
      isVerified: true,
      thumbnailUrl: article.thumbnailAsset,
      mediaType: MediaType.image,
      headline: article.headline,
      excerpt: article.body.length > 120
          ? '${article.body.substring(0, 120)}...'
          : article.body,
      category: article.category,
      readTimeMinutes: readTime,
      likeCount: article.likesCount,
      commentCount: article.commentsCount,
      saveCount: 0,
      shareCount: 0,
      isLiked: article.isLiked,
      isSaved: article.isBookmarked,
      colorIndex: index,
    );
  }
}

// ── Header (logo + search + scrollable tab pills) ─────────────────────────────

class _Header extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const _Header({required this.tabIndex, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.transparent],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo + search row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Startups',
                          style: AppTypography.displaySmallBold.copyWith(
                            fontSize: 20,
                            color: AppColors.primaryDefault,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'India',
                          style: AppTypography.displaySmallBold.copyWith(
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/search'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.search_rounded,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Tab pills
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 12),
                itemCount: _tabs.length,
                itemBuilder: (context, i) => _TabPill(
                  label: _tabs[i],
                  active: tabIndex == i,
                  onTap: () => onTabChanged(i),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryDefault
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.textSmall.copyWith(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Full-screen card ───────────────────────────────────────────────────────────

class _MediaCard extends StatefulWidget {
  final MediaPost post;

  const _MediaCard({required this.post});

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  late bool _isLiked;
  late bool _isSaved;
  late int _likeCount;

  // ── VIDEO PLAYBACK — Add support in 4 steps ──────────────────────────────
  // 1. pubspec.yaml: video_player: ^2.x.x
  //
  // 2. Add to this class:
  //      VideoPlayerController? _videoController;
  //    In initState (after super.initState):
  //      if (widget.post.mediaType == MediaType.video &&
  //          widget.post.mediaUrl != null) {
  //        _videoController = VideoPlayerController.networkUrl(
  //            Uri.parse(widget.post.mediaUrl!))
  //          ..initialize().then((_) {
  //            setState(() {});
  //            _videoController!.play();
  //            _videoController!.setLooping(true);
  //          });
  //      }
  //    In dispose (before super.dispose):
  //      _videoController?.dispose();
  //
  // 3. Pass _videoController to _MediaLayer below.
  //
  // 4. In _MediaLayer.build(), the MediaType.video branch is already there —
  //    remove the _GradientFallback placeholder and add:
  //      VideoPlayer(_videoController!)
  //    wrapped in a FittedBox(fit: BoxFit.cover).
  //    All overlays (sidebar, bottom content) need zero changes.
  // ────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _likeCount = widget.post.likeCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Firestore write — same pattern as news_tile.dart
  }

  void _toggleSave() {
    setState(() => _isSaved = !_isSaved);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 1: Media ─────────────────────────────────────────────
        _MediaLayer(post: widget.post),

        // ── Layer 2: Gradient scrims ───────────────────────────────────
        const _Scrim(),

        // ── Layer 3: Right sidebar ─────────────────────────────────────
        Positioned(
          right: 12,
          bottom: bottomPad + 100,
          child: _SidebarActions(
            likeCount: _likeCount,
            commentCount: widget.post.commentCount,
            saveCount: widget.post.saveCount,
            shareCount: widget.post.shareCount,
            isLiked: _isLiked,
            isSaved: _isSaved,
            authorAvatarUrl: widget.post.authorAvatarUrl,
            onLike: _toggleLike,
            onSave: _toggleSave,
            onComment: () {},
            onShare: () {},
          ),
        ),

        // ── Layer 4: Bottom content ────────────────────────────────────
        Positioned(
          left: 0,
          right: 80,
          bottom: 0,
          child: _BottomContent(
            post: widget.post,
            bottomPad: bottomPad,
          ),
        ),
      ],
    );
  }
}

// ── Media layer (image now; video-ready slot) ──────────────────────────────────

class _MediaLayer extends StatelessWidget {
  final MediaPost post;
  // VIDEO: add `final VideoPlayerController? videoController;` here

  const _MediaLayer({required this.post});

  @override
  Widget build(BuildContext context) {
    switch (post.mediaType) {
      case MediaType.video:
        // VIDEO: Replace _GradientFallback with:
        //   videoController!.value.isInitialized
        //     ? FittedBox(
        //         fit: BoxFit.cover,
        //         child: SizedBox(
        //           width: videoController!.value.size.width,
        //           height: videoController!.value.size.height,
        //           child: VideoPlayer(videoController!),
        //         ))
        //     : const Center(child: CircularProgressIndicator())
        return _GradientFallback(index: post.colorIndex);

      case MediaType.image:
        if (post.thumbnailUrl.startsWith('http')) {
          return CachedNetworkImage(
            imageUrl: post.thumbnailUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) =>
                _GradientFallback(index: post.colorIndex),
          );
        }
        return _GradientFallback(index: post.colorIndex);
    }
  }
}

class _GradientFallback extends StatelessWidget {
  final int index;

  const _GradientFallback({required this.index});

  @override
  Widget build(BuildContext context) {
    final base = _cardColors[index % _cardColors.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, base.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// ── Gradient scrims ───────────────────────────────────────────────────────────

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top scrim (for header readability)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom scrim (for content readability)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 380,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Right sidebar actions ─────────────────────────────────────────────────────

class _SidebarActions extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final String authorAvatarUrl;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const _SidebarActions({
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.shareCount,
    required this.isLiked,
    required this.isSaved,
    required this.authorAvatarUrl,
    required this.onLike,
    required this.onSave,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SidebarBtn(
          icon: isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: _fmt(likeCount),
          color: isLiked ? Colors.redAccent : Colors.white,
          onTap: onLike,
        ),
        const SizedBox(height: 22),
        _SidebarBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: _fmt(commentCount),
          color: Colors.white,
          onTap: onComment,
        ),
        const SizedBox(height: 22),
        _SidebarBtn(
          icon: isSaved
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: _fmt(saveCount),
          color: isSaved ? AppColors.primaryDefault : Colors.white,
          onTap: onSave,
        ),
        const SizedBox(height: 22),
        _SidebarBtn(
          icon: Icons.reply_rounded,
          label: _fmt(shareCount),
          color: Colors.white,
          onTap: onShare,
          mirrorHorizontal: true,
        ),
        const SizedBox(height: 22),
        // Author avatar
        ClipOval(
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: AppColors.darkSurface,
            ),
            child: authorAvatarUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: authorAvatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20),
                  )
                : const Icon(Icons.person_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _SidebarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool mirrorHorizontal;

  const _SidebarBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.mirrorHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scaleX: mirrorHorizontal ? -1.0 : 1.0,
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.textSmall.copyWith(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom content overlay ────────────────────────────────────────────────────

class _BottomContent extends StatelessWidget {
  final MediaPost post;
  final double bottomPad;

  const _BottomContent({required this.post, required this.bottomPad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row ──────────────────────────────────────────────
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 34,
                  height: 34,
                  color: AppColors.darkSurface,
                  child: post.authorAvatarUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: post.authorAvatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 16),
                        )
                      : const Icon(Icons.person_rounded,
                          color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textSmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            size: 13,
                            color: AppColors.primaryDefault),
                      ],
                    ),
                    Text(
                      post.authorRole,
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _FollowButton(),
            ],
          ),
          const SizedBox(height: 12),

          // ── Headline ────────────────────────────────────────────────
          Text(
            post.headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 18,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // ── Excerpt ─────────────────────────────────────────────────
          if (post.excerpt.isNotEmpty)
            Text(
              post.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),

          // ── Category tag + read time + follow topic ─────────────────
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                post.category,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded,
                  size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                '${post.readTimeMinutes} min read',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Follow Topic button ──────────────────────────────────────
          _FollowTopicBtn(topic: post.category),
        ],
      ),
    );
  }
}

// Simple Follow (author) button — stateless for now
class _FollowButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Follow',
        style: AppTypography.textSmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Follow Topic button — wired to Firestore via userTopicsProvider ────────────

class _FollowTopicBtn extends ConsumerWidget {
  final String topic;

  const _FollowTopicBtn({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(userTopicsProvider);
    final followed = topicsAsync.asData?.value ?? [];
    final slug = topic.toLowerCase();
    final isFollowing = followed.contains(slug);

    return GestureDetector(
      onTap: () async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final repo = ref.read(firestoreRepositoryProvider);
        if (isFollowing) {
          await repo.unfollowTopic(uid, slug);
        } else {
          await repo.followTopic(uid, slug);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isFollowing
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white70,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowing ? Icons.check_rounded : Icons.add_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              isFollowing ? 'Following $topic' : 'Follow $topic',
              style: AppTypography.textSmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
