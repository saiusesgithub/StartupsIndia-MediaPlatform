import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../domain/models/news_article.dart';
import '../widgets/comment_tile.dart';

class CommentsScreen extends StatefulWidget {
  final NewsArticle article;

  const CommentsScreen({super.key, required this.article});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  late List<CommentNode> _comments;
  final Set<String> _expandedThreads = <String>{};
  final Set<String> _freshlyInserted = <String>{};

  @override
  void initState() {
    super.initState();
    _comments = _mockComments;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.grayscaleWhite,
      appBar: AppBar(
        backgroundColor: AppColors.grayscaleWhite,
        surfaceTintColor: AppColors.grayscaleWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.grayscaleTitleActive,
            size: 20,
          ),
        ),
        title: Text(
          'Comments',
          style: AppTypography.textMedium.copyWith(
            color: AppColors.grayscaleTitleActive,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 90),
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          final comment = _comments[index];
          final bool isFresh = _freshlyInserted.contains(comment.id);

          return AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            offset: isFresh ? const Offset(0, -0.16) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 260),
              opacity: isFresh ? 0.85 : 1,
              child: CommentTile(
                key: ValueKey<String>(comment.id),
                comment: comment,
                isExpanded: _expandedThreads.contains(comment.id),
                onReplyTap: _handleReplyTap,
                onToggleLike: _toggleLikeById,
                onToggleExpand: _toggleThreadExpansion,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildComposerBar(),
    );
  }

  Widget _buildComposerBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grayscaleWhite,
          border: Border(
            top: BorderSide(color: AppColors.grayscaleLine.withOpacity(0.8)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grayscaleBodyText),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _commentController,
                  focusNode: _inputFocusNode,
                  style: AppTypography.textMedium.copyWith(
                    color: AppColors.grayscaleTitleActive,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type your comment',
                    hintStyle: AppTypography.textMedium.copyWith(
                      color: AppColors.grayscaleButtonText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              height: 42,
              child: ElevatedButton(
                onPressed: _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDefault,
                  foregroundColor: AppColors.grayscaleWhite,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final id = 'comment_${DateTime.now().microsecondsSinceEpoch}';
    final newComment = CommentNode(
      id: id,
      userName: 'You',
      userAvatar: 'assets/images/thumb_politics.png',
      timeAgo: 'now',
      text: text,
      likesCount: 0,
      isLiked: false,
      replies: const <CommentNode>[],
    );

    setState(() {
      _comments.insert(0, newComment);
      _freshlyInserted.add(id);
    });

    _commentController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _freshlyInserted.remove(id));
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comment posted')));
  }

  void _handleReplyTap(String userName) {
    final mention = '@$userName ';
    final current = _commentController.text;
    final next = current.startsWith(mention) ? current : '$mention$current';

    _commentController
      ..text = next
      ..selection = TextSelection.collapsed(offset: next.length);

    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  void _toggleThreadExpansion(String commentId) {
    setState(() {
      if (_expandedThreads.contains(commentId)) {
        _expandedThreads.remove(commentId);
      } else {
        _expandedThreads.add(commentId);
      }
    });
  }

  void _toggleLikeById(String commentId) {
    setState(() {
      _comments = _comments
          .map((item) => _toggleLikeInNode(item, commentId))
          .toList(growable: false);
    });
  }

  CommentNode _toggleLikeInNode(CommentNode node, String targetId) {
    if (node.id == targetId) {
      final nextLiked = !node.isLiked;
      return node.copyWith(
        isLiked: nextLiked,
        likesCount: nextLiked
            ? node.likesCount + 1
            : (node.likesCount - 1).clamp(0, 9999999),
      );
    }

    if (node.replies.isEmpty) {
      return node;
    }

    return node.copyWith(
      replies: node.replies
          .map((reply) => _toggleLikeInNode(reply, targetId))
          .toList(growable: false),
    );
  }

  List<CommentNode> get _mockComments => const <CommentNode>[
    CommentNode(
      id: 'c_1',
      userName: 'Wilson Franci',
      userAvatar: 'assets/images/thumb_politics.png',
      timeAgo: '4w',
      text:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      likesCount: 125,
    ),
    CommentNode(
      id: 'c_2',
      userName: 'Marley Botosh',
      userAvatar: 'assets/images/thumb_sports.png',
      timeAgo: '4w',
      text:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      likesCount: 12,
      replies: <CommentNode>[
        CommentNode(
          id: 'c_2_r1',
          userName: 'Madelyn Saris',
          userAvatar: 'assets/images/thumb_business.png',
          timeAgo: '4w',
          text: 'Lorem Ipsum is simply dummy text of the printing and type...',
          likesCount: 3,
          isLiked: true,
        ),
        CommentNode(
          id: 'c_2_r2',
          userName: 'Corey Geidt',
          userAvatar: 'assets/images/thumb_tech.png',
          timeAgo: '2w',
          text: 'Adding another nested thought here to mimic a long thread.',
          likesCount: 2,
        ),
      ],
    ),
    CommentNode(
      id: 'c_3',
      userName: 'Alfonso Septimus',
      userAvatar: 'assets/images/thumb_tech.png',
      timeAgo: '4w',
      text:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      likesCount: 14000,
      isLiked: true,
    ),
    CommentNode(
      id: 'c_4',
      userName: 'Omar Herwitz',
      userAvatar: 'assets/images/thumb_business.png',
      timeAgo: '4w',
      text:
          'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      likesCount: 16,
    ),
  ];
}
