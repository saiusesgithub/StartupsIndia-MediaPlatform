import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/models/news_article_model.dart';
import '../../../../../core/repository/firestore_repository.dart';
import '../../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../../theme/style_guide.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _coverImageBytes;
  XFile? _coverImageFile;
  bool _isPublishing = false;

  bool get _canPublish {
    return _titleController.text.trim().isNotEmpty && _coverImageBytes != null;
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onInputChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.grayscaleWhite,
      appBar: AppBar(
        centerTitle: true,
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
          'Create News',
          style: AppTypography.textMedium.copyWith(
            color: AppColors.grayscaleTitleActive,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.grayscaleBodyText,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCoverSection(),
            const SizedBox(height: 12),
            _buildTitleInput(),
            const SizedBox(height: 8),
            _buildBodyInput(),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: _buildEditorBottomBars(),
      ),
    );
  }

  Widget _buildCoverSection() {
    final hasImage = _coverImageBytes != null;

    return GestureDetector(
      onTap: _pickCoverImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 182,
          width: double.infinity,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_coverImageBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.grayscaleWhite,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.grayscaleBodyText,
                        ),
                      ),
                    ),
                  ],
                )
              : CustomPaint(
                  painter: _DashedBorderPainter(
                    color: AppColors.grayscaleButtonText.withValues(alpha: 0.6),
                    radius: 12,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: AppColors.grayscaleBodyText,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Cover Photo',
                          style: AppTypography.textMedium.copyWith(
                            color: AppColors.grayscaleBodyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          style: AppTypography.displaySmallBold.copyWith(
            color: AppColors.grayscaleTitleActive,
            fontSize: 36,
            height: 1.2,
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'News title',
            hintStyle: AppTypography.displaySmallBold.copyWith(
              color: AppColors.grayscaleButtonText,
              fontSize: 34,
              height: 1.2,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: AppColors.grayscaleLine),
      ],
    );
  }

  Widget _buildBodyInput() {
    return TextField(
      controller: _bodyController,
      focusNode: _bodyFocusNode,
      style: AppTypography.textMedium.copyWith(
        color: AppColors.grayscaleBodyText,
        height: 1.6,
      ),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      maxLines: null,
      minLines: 14,
      decoration: InputDecoration(
        hintText: 'Add News/Article',
        hintStyle: AppTypography.textLarge.copyWith(
          color: AppColors.grayscaleButtonText,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEditorBottomBars() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grayscaleWhite,
          border: Border(
            top: BorderSide(
              color: AppColors.grayscaleLine.withValues(alpha: 0.85),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.grayscaleInputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.grayscaleLine),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolButton(icon: Icons.format_bold_rounded),
                    _toolButton(icon: Icons.format_italic_rounded),
                    _toolButton(icon: Icons.format_list_bulleted_rounded),
                    _toolButton(icon: Icons.link_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _toolButton(icon: Icons.text_fields_rounded, label: 'Aa'),
                _toolButton(icon: Icons.format_align_left_rounded),
                _toolButton(icon: Icons.image_outlined),
                _toolButton(icon: Icons.more_horiz_rounded),
                const Spacer(),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: !_canPublish || _isPublishing ? null : _publish,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      disabledBackgroundColor:
                          AppColors.grayscaleSecondaryButton,
                      backgroundColor: AppColors.primaryDefault,
                      foregroundColor: AppColors.grayscaleWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: _isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.grayscaleWhite,
                            ),
                          )
                        : Text(
                            'Publish',
                            style: AppTypography.textMedium.copyWith(
                              color: _canPublish
                                  ? AppColors.grayscaleWhite
                                  : AppColors.grayscaleButtonText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton({required IconData icon, String? label}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      onPressed: () {},
      icon: label == null
          ? Icon(icon, size: 20, color: AppColors.grayscaleBodyText)
          : Text(
              label,
              style: AppTypography.textMedium.copyWith(
                color: AppColors.grayscaleBodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _coverImageBytes = bytes;
      _coverImageFile = image;
    });
  }

  Future<void> _publish() async {
    // Validate
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (_coverImageBytes == null || _coverImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cover image')),
      );
      return;
    }

    // Show loading
    setState(() => _isPublishing = true);

    try {
      // Read providers before async operations to avoid ref binding issues
      final authRepository = ref.read(authRepositoryProvider);
      final firestoreRepository = ref.read(firestoreRepositoryProvider);

      // Get current user ID
      final userModel = await authRepository.getCurrentUserModel();
      if (userModel == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to Firebase Storage
      final Uint8List imageBytes = await _coverImageFile!.readAsBytes();
      String imageUrl;
      try {
        imageUrl = await firestoreRepository.uploadImage(
          imageBytes,
          'article_covers/',
        );
      } catch (uploadError) {
        // If upload fails (e.g., CORS on web), use placeholder
        imageUrl = 'assets/images/placeholder.png';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image upload failed, using placeholder image'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Get current timestamp
      final now = DateTime.now();

      // Create article model
      final article = NewsArticleModel(
        id: '${userModel.uid}_${now.millisecondsSinceEpoch}',
        createdAt: now,
        authorId: userModel.uid,
        category: 'Trending', // Default category
        headline: _titleController.text.trim(),
        sourceName:
            userModel.displayName ??
            'Anonymous', // ignore: unnecessary_null_coalescing
        sourceId: userModel.uid,
        sourceLogoAsset:
            userModel.avatarUrl ??
            'assets/icons/default_avatar.png', // ignore: unnecessary_null_coalescing
        thumbnailAsset: imageUrl,
        timeAgo: 'now',
        body: _bodyController.text.trim(),
        likesCount: 0,
        commentsCount: 0,
        isSourceFollowing: false,
        isBookmarked: false,
        isLiked: false,
        isTrending: false,
        likedBy: [],
        bookmarkedBy: [],
      );

      // Save article to Firestore
      await firestoreRepository.createArticle(article);

      if (!mounted) return;

      // Success feedback
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('News Published Successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isPublishing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, this.radius = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    const dashWidth = 7.0;
    const dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
