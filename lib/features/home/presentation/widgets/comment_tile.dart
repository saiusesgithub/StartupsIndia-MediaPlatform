import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class CommentNode {
  final String id;
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String text;
  final int likesCount;
  final bool isLiked;
  final List<CommentNode> replies;

  const CommentNode({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.text,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const <CommentNode>[],
  });

  CommentNode copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? timeAgo,
    String? text,
    int? likesCount,
    bool? isLiked,
    List<CommentNode>? replies,
  }) {
    return CommentNode(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      timeAgo: timeAgo ?? this.timeAgo,
      text: text ?? this.text,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }
}

class CommentTile extends StatelessWidget {
  final CommentNode comment;
  final int depth;
  final bool isExpanded;
  final ValueChanged<String> onReplyTap;
  final ValueChanged<String> onToggleLike;
  final ValueChanged<String> onToggleExpand;

  const CommentTile({
    super.key,
    required this.comment,
    this.depth = 0,
    required this.isExpanded,
    required this.onReplyTap,
    required this.onToggleLike,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final visibleReplies = _visibleReplies();
    final bool hasHiddenReplies =
        !isExpanded && comment.replies.length > visibleReplies.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(18 + (depth * 18), 10, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentAvatar(url: comment.userAvatar, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName,
                      style: AppTypography.textMedium.copyWith(
                        color: AppColors.grayscaleTitleActive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: AppTypography.textMedium.copyWith(
                        color: AppColors.grayscaleTitleActive,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          comment.timeAgo,
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleButtonText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => onToggleLike(comment.id),
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border_rounded,
                                size: 14,
                                color: comment.isLiked
                                    ? const Color(0xFFE91E63)
                                    : AppColors.grayscaleButtonText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatCount(comment.likesCount)} likes',
                                style: AppTypography.textSmall.copyWith(
                                  color: AppColors.grayscaleButtonText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => onReplyTap(comment.userName),
                          child: Text(
                            'reply',
                            style: AppTypography.textSmall.copyWith(
                              color: AppColors.grayscaleButtonText,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  ...visibleReplies.map(
                    (reply) => CommentTile(
                      key: ValueKey<String>(reply.id),
                      comment: reply,
                      depth: depth + 1,
                      isExpanded: isExpanded,
                      onReplyTap: onReplyTap,
                      onToggleLike: onToggleLike,
                      onToggleExpand: onToggleExpand,
                    ),
                  ),
                  if (hasHiddenReplies || isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 4),
                      child: TextButton(
                        onPressed: () => onToggleExpand(comment.id),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          hasHiddenReplies
                              ? 'See more (${comment.replies.length - visibleReplies.length})'
                              : 'See less',
                          style: AppTypography.textMedium.copyWith(
                            color: AppColors.grayscaleBodyText,
                            fontWeight: FontWeight.w500,
                          ),
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

  List<CommentNode> _visibleReplies() {
    if (comment.replies.isEmpty) {
      return const <CommentNode>[];
    }
    if (isExpanded) {
      return comment.replies;
    }
    return <CommentNode>[comment.replies.first];
  }

  String _formatCount(int value) {
    if (value >= 1000) {
      final k = value / 1000;
      return k % 1 == 0
          ? '${k.toStringAsFixed(0)}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _CommentAvatar extends StatelessWidget {
  final String url;
  final double radius;

  const _CommentAvatar({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
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
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: AppColors.grayscaleButtonText,
      ),
    );
  }
}
