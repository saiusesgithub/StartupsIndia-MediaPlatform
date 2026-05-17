import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../../notifications/domain/models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final NotificationType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String avatarLabel;
  final bool isDark;
  final bool isFollowing;
  final VoidCallback? onFollowTap;

  const NotificationTile({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.avatarLabel,
    required this.isDark,
    this.isFollowing = false,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;
    final subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.grayscaleBodyText;
    final timeColor =
        isDark ? AppColors.darkTextSecondary : AppColors.grayscaleButtonText;
    final avatarBg = isDark
        ? AppColors.darkInputBackground
        : AppColors.grayscaleSecondaryButton;
    final avatarText =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(avatarBg, avatarText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.textSmall.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.textSmall.copyWith(
                    color: subtitleColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeAgo,
                  style: AppTypography.textSmall.copyWith(
                    color: timeColor,
                    fontSize: 11,
                  ),
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

  Widget _buildAvatar(Color bgColor, Color textColor) {
    final badgeBg =
        isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: bgColor,
          child: Text(
            avatarLabel,
            style: AppTypography.textSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
              color: badgeBg,
              border: Border.all(color: badgeBg, width: 1.5),
            ),
            child: Icon(_statusIcon, size: 11, color: _statusColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: onFollowTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.primaryDefault : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryDefault),
        ),
        child: isFollowing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
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
