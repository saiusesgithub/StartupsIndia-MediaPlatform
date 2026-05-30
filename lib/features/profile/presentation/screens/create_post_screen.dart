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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.grayscaleWhite,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.grayscaleWhite,
        surfaceTintColor: isDark
            ? AppColors.darkBackground
            : AppColors.grayscaleWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
            size: 20,
          ),
        ),
        title: Text(
          'Create News',
          style: AppTypography.textMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
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
            _buildCoverSection(isDark),
            const SizedBox(height: 12),
            _buildTitleInput(isDark),
            const SizedBox(height: 8),
            _buildBodyInput(isDark),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: _buildEditorBottomBars(isDark),
      ),
    );
  }

  Widget _buildCoverSection(bool isDark) {
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
                    color:
                        (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleButtonText)
                            .withValues(alpha: 0.6),
                    radius: 12,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.grayscaleBodyText,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Cover Photo',
                          style: AppTypography.textMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleBodyText,
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

  Widget _buildTitleInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          style: AppTypography.displaySmallBold.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.grayscaleTitleActive,
            fontSize: 36,
            height: 1.2,
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'News title',
            hintStyle: AppTypography.displaySmallBold.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
              fontSize: 34,
              height: 1.2,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 6),
        Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
        ),
      ],
    );
  }

  Widget _buildBodyInput(bool isDark) {
    return TextField(
      controller: _bodyController,
      focusNode: _bodyFocusNode,
      style: AppTypography.textMedium.copyWith(
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.grayscaleBodyText,
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
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.grayscaleButtonText,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEditorBottomBars(bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.grayscaleWhite,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.grayscaleLine.withValues(alpha: 0.85),
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
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.grayscaleInputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.grayscaleLine,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolButton(
                      icon: Icons.format_bold_rounded,
                      isDark: isDark,
                    ),
                    _toolButton(
                      icon: Icons.format_italic_rounded,
                      isDark: isDark,
                    ),
                    _toolButton(
                      icon: Icons.format_list_bulleted_rounded,
                      isDark: isDark,
                    ),
                    _toolButton(icon: Icons.link_rounded, isDark: isDark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _toolButton(
                  icon: Icons.text_fields_rounded,
                  label: 'Aa',
                  isDark: isDark,
                ),
                _toolButton(
                  icon: Icons.format_align_left_rounded,
                  isDark: isDark,
                ),
                _toolButton(icon: Icons.image_outlined, isDark: isDark),
                _toolButton(icon: Icons.more_horiz_rounded, isDark: isDark),
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

  Widget _toolButton({
    required IconData icon,
    required bool isDark,
    String? label,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      onPressed: () {},
      icon: label == null
          ? Icon(
              icon,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            )
          : Text(
              label,
              style: AppTypography.textMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
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

      // Upload image to Cloudinary
      final String imageUrl = await firestoreRepository.uploadImage(
        _coverImageFile!.path,
      );

      // Get current timestamp
      final now = DateTime.now();

      // Create article model
      final article = NewsArticleModel(
        id: '${userModel.uid}_${now.millisecondsSinceEpoch}',
        createdAt: now,
        authorId: userModel.uid,
        category: 'Trending', // Default category
        headline: _titleController.text.trim(),
        sourceName: userModel.displayName.isEmpty
            ? 'Anonymous'
            : userModel.displayName,
        sourceId: userModel.uid,
        sourceLogoAsset: userModel.avatarUrl.isEmpty
            ? 'assets/icons/default_avatar.png'
            : userModel.avatarUrl,
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

      // Success feedback on Home screen
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/home', (route) => false);
      messenger.showSnackBar(const SnackBar(content: Text('News Published!')));
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
