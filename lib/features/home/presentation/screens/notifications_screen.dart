import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/style_guide.dart';
import '../widgets/notification_tile.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../../../core/utils/time_format_helper.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _followingIds = {'follow_01'};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.grayscaleSecondaryButton,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) => _buildList(notifications, isDark),
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDefault,
                  ),
                ),
                error: (_, _) => _buildList(const [], isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.grayscaleLine;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.grayscaleTitleActive;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: textColor,
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              'Notifications',
              textAlign: TextAlign.center,
              style: AppTypography.textSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          // Balance spacer
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildList(List<AppNotification> notifications, bool isDark) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleButtonText,
            ),
            const SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: AppTypography.textSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleBodyText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'re all caught up!',
              style: AppTypography.textSmall.copyWith(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.grayscaleButtonText,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final older = <AppNotification>[];

    for (final n in notifications) {
      if (n.createdAt.isAfter(startOfToday)) {
        today.add(n);
      } else if (n.createdAt.isAfter(startOfYesterday)) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (today.isNotEmpty) ...[
          _buildGroupHeader('Today', isDark),
          _buildGroupSliver(today, isDark),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildGroupHeader('Yesterday', isDark),
          _buildGroupSliver(yesterday, isDark),
        ],
        if (older.isNotEmpty) ...[
          _buildGroupHeader('Earlier', isDark),
          _buildGroupSliver(older, isDark),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  SliverToBoxAdapter _buildGroupHeader(String title, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(
          title.toUpperCase(),
          style: AppTypography.textSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
          ),
        ),
      ),
    );
  }

  SliverList _buildGroupSliver(List<AppNotification> items, bool isDark) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return NotificationTile(
          type: item.type,
          title: item.title,
          subtitle: item.subtitle,
          timeAgo: formatArticleTimestamp(item.createdAt),
          avatarLabel: item.avatarLabel,
          isDark: isDark,
          isFollowing: _followingIds.contains(item.id),
          onFollowTap: item.type == NotificationType.follow
              ? () {
                  setState(() {
                    if (_followingIds.contains(item.id)) {
                      _followingIds.remove(item.id);
                    } else {
                      _followingIds.add(item.id);
                    }
                  });
                }
              : null,
        );
      },
    );
  }
}
