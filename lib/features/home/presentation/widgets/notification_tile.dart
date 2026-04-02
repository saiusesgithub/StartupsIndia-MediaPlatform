import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

enum NotificationType { news, follow, interaction }

class NotificationTile extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String avatarLabel;
  final bool isFollowing;
  final VoidCallback? onFollowTap;

  const NotificationTile({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.avatarLabel,
    this.isFollowing = false,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grayscaleWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayscaleLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textSmall.copyWith(
                    color: AppColors.grayscaleTitleActive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.textSmall.copyWith(
                    color: AppColors.grayscaleBodyText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (type == NotificationType.follow)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFollowButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.grayscaleSecondaryButton,
          child: Text(
            avatarLabel,
            style: AppTypography.textSmall.copyWith(
              color: AppColors.grayscaleTitleActive,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              _statusIcon,
              size: 12,
              color: _statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return ElevatedButton(
      onPressed: onFollowTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(92, 34),
        backgroundColor:
            isFollowing ? AppColors.primaryDefault : Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(
            color: AppColors.primaryDefault,
            width: 1,
          ),
        ),
      ),
      child: isFollowing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Following',
                  style: AppTypography.textSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          : Text(
              'Follow',
              style: AppTypography.textSmall.copyWith(
                color: AppColors.primaryDefault,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
    );
  }

  IconData get _statusIcon {
    switch (type) {
      case NotificationType.news:
        return Icons.newspaper_rounded;
      case NotificationType.follow:
        return Icons.person_add_alt_1_rounded;
      case NotificationType.interaction:
        return Icons.favorite_rounded;
    }
  }

  Color get _statusColor {
    switch (type) {
      case NotificationType.news:
        return AppColors.primaryDefault;
      case NotificationType.follow:
        return AppColors.successDefault;
      case NotificationType.interaction:
        return const Color(0xFFFF4757);
    }
  }
}
