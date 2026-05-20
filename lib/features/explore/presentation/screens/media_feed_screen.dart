import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/providers/user_topics_provider.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/widgets/guest_gate.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/media_post.dart';
import '../../domain/models/post_model.dart';
import '../providers/post_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/data/repositories/report_repository.dart';
import '../../../home/presentation/widgets/report_sheet.dart';

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
    List<PostModel> posts,
    List<String> followedTopics,
  ) {
    final tab = _tabs[_tabIndex];

    final items = posts
        .asMap()
        .entries
        .map((e) => _postToMediaPost(e.value, e.key))
        .toList();

    if (tab == 'For You') {
      if (followedTopics.isEmpty) return items;
      final followed = items
          .where((p) => followedTopics.contains(p.category.toLowerCase()))
          .toList();
      final rest = items
          .where((p) => !followedTopics.contains(p.category.toLowerCase()))
          .toList();
      return [...followed, ...rest];
    }

    if (tab == 'Trending') {
      final sorted = List<MediaPost>.from(items)
        ..sort((a, b) =>
            (b.likeCount + b.commentCount).compareTo(a.likeCount + a.commentCount));
      return sorted;
    }

    final filter = _tabCategoryMap[tab] ?? '';
    if (filter.isEmpty) return items;
    final filtered =
        items.where((p) => p.category.toLowerCase().contains(filter)).toList();
    return filtered.isNotEmpty ? filtered : items;
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);
    final topicsAsync = ref.watch(userTopicsProvider);

    final posts = postsAsync.asData?.value ?? [];
    final followedTopics = topicsAsync.asData?.value ?? [];

    final feedItems = _buildFeed(posts, followedTopics);
    final isGuest = FirebaseAuth.instance.currentUser == null;
    const guestLimit = 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (feedItems.isEmpty)
            const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primaryDefault),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: isGuest ? guestLimit + 1 : feedItems.length,
              itemBuilder: (context, i) {
                if (isGuest && i >= guestLimit) {
                  return const GuestFeedGate();
                }
                return _MediaCard(post: feedItems[i]);
              },
            ),

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

  static MediaPost _postToMediaPost(PostModel post, int index) {
    return MediaPost(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      authorRole: post.authorRole,
      authorAvatarUrl: post.authorAvatarUrl,
      isVerified: true,
      thumbnailUrl: post.thumbnailUrl,
      mediaUrl: post.videoUrl.isNotEmpty ? post.videoUrl : null,
      mediaType:
          post.mediaType == 'video' ? MediaType.video : MediaType.image,
      sourceType: MediaSource.post,
      headline: post.headline,
      excerpt: post.excerpt,
      category: post.category,
      readTimeMinutes: 0,
      likeCount: post.likesCount,
      commentCount: post.commentsCount,
      saveCount: post.bookmarkedBy.length,
      shareCount: post.shareCount,
      isLiked: post.likedBy
          .contains(FirebaseAuth.instance.currentUser?.uid ?? ''),
      isSaved: post.bookmarkedBy
          .contains(FirebaseAuth.instance.currentUser?.uid ?? ''),
      colorIndex: index,
    );
  }

}

// ── Header ─────────────────────────────────────────────────────────────────────

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
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                ],
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 12),
                itemCount: _tabs.length,
                itemBuilder: (context, i) => Center(
                  child: _TabPill(
                    label: _tabs[i],
                    active: tabIndex == i,
                    onTap: () => onTabChanged(i),
                  ),
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

class _MediaCard extends ConsumerStatefulWidget {
  final MediaPost post;

  const _MediaCard({required this.post});

  @override
  ConsumerState<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends ConsumerState<_MediaCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late bool _isSaved;
  late int _likeCount;
  late int _commentCount;
  late int _shareCount;

  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  bool _showHeartOverlay = false;
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    _likeCount = widget.post.likeCount;
    _commentCount = widget.post.commentCount;
    _shareCount = widget.post.shareCount;

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          if (mounted) setState(() => _showHeartOverlay = false);
        }
      });
    _heartAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));

    if (widget.post.mediaType == MediaType.video &&
        widget.post.mediaUrl != null) {
      _initVideo(widget.post.mediaUrl!);
    }
  }

  Future<void> _initVideo(String url) async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    if (mounted) {
      setState(() => _videoInitialized = true);
      _videoController!.play();
      _videoController!.setLooping(true);
    }
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _toggleLike() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      if (widget.post.sourceType == MediaSource.post) {
        await ref
            .read(postRepositoryProvider)
            .togglePostLike(widget.post.id, uid);
      } else {
        await ref
            .read(firestoreRepositoryProvider)
            .toggleLike(widget.post.id, uid);
      }
    } catch (_) {
      // Revert optimistic update on failure
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _toggleSave() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _isSaved = !_isSaved);
    try {
      if (widget.post.sourceType == MediaSource.post) {
        await ref
            .read(postRepositoryProvider)
            .togglePostBookmark(widget.post.id, uid);
      } else {
        await ref
            .read(firestoreRepositoryProvider)
            .toggleBookmark(widget.post.id, uid);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaved = !_isSaved);
    }
  }

  Future<void> _share() async {
    final text = widget.post.headline;
    await Share.share(text);
    // Increment share count in Firestore (best-effort)
    final uid = _uid;
    if (uid != null && widget.post.sourceType == MediaSource.post) {
      setState(() => _shareCount++);
      try {
        await ref
            .read(postRepositoryProvider)
            .incrementPostShareCount(widget.post.id);
      } catch (_) {}
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentSheet(post: widget.post),
    );
  }

  void _toggleVideoPlayback() {
    final ctrl = _videoController;
    if (ctrl == null || !_videoInitialized) return;
    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
      } else {
        ctrl.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isPlaying = _videoController?.value.isPlaying ?? false;

    return GestureDetector(
      onTap: _toggleVideoPlayback,
      onDoubleTap: () {
        if (!_isLiked) _toggleLike();
        setState(() => _showHeartOverlay = true);
        _heartCtrl.forward(from: 0);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _MediaLayer(
            post: widget.post,
            videoController: _videoController,
            videoInitialized: _videoInitialized,
          ),
          const _Scrim(),

          // Double-tap heart overlay
          if (_showHeartOverlay)
            Center(
              child: ScaleTransition(
                scale: _heartAnim,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 90,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 20)],
                ),
              ),
            ),

          // Pause indicator
          if (_videoInitialized && !isPlaying)
            const Center(
              child: Icon(Icons.pause_circle_filled_rounded,
                  color: Colors.white54, size: 64),
            ),

          // Right sidebar
          Positioned(
            right: 12,
            bottom: bottomPad + 16,
            child: _SidebarActions(
              likeCount: _likeCount,
              commentCount: _commentCount,
              saveCount: widget.post.saveCount,
              shareCount: _shareCount,
              isLiked: _isLiked,
              isSaved: _isSaved,
              onLike: _toggleLike,
              onSave: _toggleSave,
              onComment: _showComments,
              onShare: _share,
            ),
          ),

          // Bottom content
          Positioned(
            left: 0,
            right: 72,
            bottom: 0,
            child: _BottomContent(
              post: widget.post,
              bottomPad: bottomPad,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Media layer ────────────────────────────────────────────────────────────────

class _MediaLayer extends StatelessWidget {
  final MediaPost post;
  final VideoPlayerController? videoController;
  final bool videoInitialized;

  const _MediaLayer({
    required this.post,
    this.videoController,
    this.videoInitialized = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (post.mediaType) {
      case MediaType.video:
        if (videoInitialized && videoController != null) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: videoController!.value.size.width,
              height: videoController!.value.size.height,
              child: VideoPlayer(videoController!),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            if (post.thumbnailUrl.startsWith('http'))
              CachedNetworkImage(
                imageUrl: post.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    _GradientFallback(index: post.colorIndex),
              )
            else
              _GradientFallback(index: post.colorIndex),
            const Center(
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2),
            ),
          ],
        );

      case MediaType.image:
        if (post.thumbnailUrl.startsWith('http')) {
          return CachedNetworkImage(
            imageUrl: post.thumbnailUrl,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) =>
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

// ── Gradient scrims ────────────────────────────────────────────────────────────

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 320,
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

// ── Right sidebar ──────────────────────────────────────────────────────────────

class _SidebarActions extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
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
          animate: true,
        ),
        const SizedBox(height: 20),
        _SidebarBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: _fmt(commentCount),
          color: Colors.white,
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        _SidebarBtn(
          icon: isSaved
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          label: _fmt(saveCount),
          color: isSaved ? AppColors.primaryDefault : Colors.white,
          onTap: onSave,
        ),
        const SizedBox(height: 20),
        _SidebarBtn(
          icon: Icons.reply_rounded,
          label: _fmt(shareCount),
          color: Colors.white,
          onTap: onShare,
          mirrorHorizontal: true,
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _SidebarBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool mirrorHorizontal;
  final bool animate;

  const _SidebarBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.mirrorHorizontal = false,
    this.animate = false,
  });

  @override
  State<_SidebarBtn> createState() => _SidebarBtnState();
}

class _SidebarBtnState extends State<_SidebarBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.animate) _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Transform.scale(
              scaleX: widget.mirrorHorizontal ? -1.0 : 1.0,
              child: Icon(widget.icon, color: widget.color, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
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

// ── Bottom content ─────────────────────────────────────────────────────────────

class _BottomContent extends StatefulWidget {
  final MediaPost post;
  final double bottomPad;

  const _BottomContent({required this.post, required this.bottomPad});

  @override
  State<_BottomContent> createState() => _BottomContentState();
}

class _BottomContentState extends State<_BottomContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPad + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author branding row
          Row(
            children: [
              Text(
                'StartupsIndia',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded,
                  size: 13, color: AppColors.primaryDefault),
            ],
          ),
          const SizedBox(height: 8),

          if (post.excerpt.isNotEmpty) ...[
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _expanded
                          ? post.excerpt
                          : (post.excerpt.length > 90
                              ? '${post.excerpt.substring(0, 90)}... '
                              : post.excerpt),
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    if (post.excerpt.length > 90)
                      TextSpan(
                        text: _expanded ? ' see less' : 'see more',
                        style: AppTypography.textSmall.copyWith(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _CategoryPill(label: post.category),
              _FollowTopicBtn(topic: post.category),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.textSmall.copyWith(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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

// ── Comment bottom sheet ───────────────────────────────────────────────────────

class _CommentSheet extends ConsumerStatefulWidget {
  final MediaPost post;

  const _CommentSheet({required this.post});

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _controller = TextEditingController();
  bool _posting = false;
  late final Stream<List<CommentModel>> _commentsStream;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(postRepositoryProvider);
    _commentsStream = widget.post.sourceType == MediaSource.post
        ? repo.watchPostComments(widget.post.id)
        : repo.watchArticleComments(widget.post.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _controller.text.trim();
    if (uid == null || text.isEmpty || _posting) return;

    setState(() => _posting = true);
    try {
      final userModel = await ref
          .read(authRepositoryProvider)
          .getCurrentUserModel();
      final authorName = userModel?.displayName.isNotEmpty == true
          ? userModel!.displayName
          : userModel?.fullName ?? 'User';
      final avatarUrl = userModel?.avatarUrl ?? '';

      final repo = ref.read(postRepositoryProvider);
      if (widget.post.sourceType == MediaSource.post) {
        await repo.addPostComment(
          postId: widget.post.id,
          userId: uid,
          authorName: authorName,
          avatarUrl: avatarUrl,
          content: text,
        );
      } else {
        await repo.addArticleComment(
          articleId: widget.post.id,
          userId: uid,
          authorName: authorName,
          avatarUrl: avatarUrl,
          content: text,
        );
      }
      _controller.clear();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Comments',
              style: AppTypography.textSmall.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Comment list
          SizedBox(
            height: 320,
            child: StreamBuilder<List<CommentModel>>(
              stream: _commentsStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryDefault, strokeWidth: 2),
                  );
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: AppTypography.textSmall.copyWith(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 14),
                  itemBuilder: (ctx, i) =>
                      _CommentTile(
                        comment: comments[i],
                        postId: widget.post.id,
                        buildContext: ctx,
                      ),
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTypography.textSmall.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: AppTypography.textSmall.copyWith(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: _posting
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                              color: AppColors.primaryDefault,
                              strokeWidth: 2),
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDefault,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final String postId;
  final BuildContext buildContext;

  const _CommentTile({
    required this.comment,
    required this.postId,
    required this.buildContext,
  });

  void _report() {
    ReportSheet.show(
      buildContext,
      title: 'Report comment',
      onSubmit: (reason) => ReportRepository().reportComment(
        commentId: comment.id,
        articleId: postId,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkSurface,
          ),
          child: ClipOval(
            child: comment.avatarUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: comment.avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white54,
                        size: 16),
                  )
                : const Icon(Icons.person_rounded,
                    color: Colors.white54, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.authorName,
                style: AppTypography.textSmall.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: AppTypography.textSmall.copyWith(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _report,
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.more_vert_rounded,
                color: Colors.white38, size: 18),
          ),
        ),
      ],
    );
  }
}
