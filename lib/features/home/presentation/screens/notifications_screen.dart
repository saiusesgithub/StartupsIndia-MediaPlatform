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
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _followingIds = {'follow_01'};

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      appBar: AppBar(
        backgroundColor: AppColors.grayscaleWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.grayscaleTitleActive,
            size: 20,
          ),
        ),
        title: Text(
          'Notification',
          style: AppTypography.displaySmallBold.copyWith(
            color: AppColors.grayscaleTitleActive,
            fontSize: 20,
          ),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: AppTypography.textSmall.copyWith(
                  color: AppColors.grayscaleBodyText,
                ),
              ),
            );
          }

          // Simple grouping: Today, Yesterday, Older
          final today = <AppNotification>[];
          final yesterday = <AppNotification>[];
          final older = <AppNotification>[];

          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);
          final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

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
                _buildGroupHeader('Today'),
                _buildGroupList(today),
              ],
              if (yesterday.isNotEmpty) ...[
                _buildGroupHeader('Yesterday'),
                _buildGroupList(yesterday),
              ],
              if (older.isNotEmpty) ...[
                _buildGroupHeader('Older'),
                _buildGroupList(older),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDefault)),
        error: (error, _) => Center(
          child: Text(
            'Failed to load notifications: $error',
            style: AppTypography.textSmall.copyWith(color: AppColors.errorDark),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildGroupHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(
          title,
          style: AppTypography.linkMedium.copyWith(
            color: AppColors.grayscaleTitleActive,
          ),
        ),
      ),
    );
  }

  SliverList _buildGroupList(List<AppNotification> items) {
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
