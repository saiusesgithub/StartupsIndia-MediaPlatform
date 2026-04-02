import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../widgets/notification_tile.dart';

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String avatarLabel;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.avatarLabel,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<String> _followingIds = {'follow_01'};

  final List<NotificationItem> _todayNotifications = const [
    NotificationItem(
      id: 'news_01',
      type: NotificationType.news,
      title: 'Breaking: Global markets rally',
      subtitle: 'Bloomberg published a major update in Business.',
      timeAgo: '15m ago',
      avatarLabel: 'B',
    ),
    NotificationItem(
      id: 'follow_01',
      type: NotificationType.follow,
      title: 'The Verge posted a new article',
      subtitle: 'Follow them to stay updated on technology news.',
      timeAgo: '42m ago',
      avatarLabel: 'TV',
    ),
    NotificationItem(
      id: 'interact_01',
      type: NotificationType.interaction,
      title: 'Ava liked your saved story',
      subtitle: '“Russian warship: Moskva sinks in Black Sea”.',
      timeAgo: '1h ago',
      avatarLabel: 'A',
    ),
  ];

  final List<NotificationItem> _yesterdayNotifications = const [
    NotificationItem(
      id: 'news_02',
      type: NotificationType.news,
      title: 'Sports alert from ESPN',
      subtitle: 'New Champions League preview is now live.',
      timeAgo: '20h ago',
      avatarLabel: 'E',
    ),
    NotificationItem(
      id: 'follow_02',
      type: NotificationType.follow,
      title: 'Reuters published politics coverage',
      subtitle: 'Tap follow to get updates in your feed.',
      timeAgo: '22h ago',
      avatarLabel: 'R',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildGroupHeader('Today, April 22'),
          _buildGroupList(_todayNotifications),
          _buildGroupHeader('Yesterday, April 21'),
          _buildGroupList(_yesterdayNotifications),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
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

  SliverList _buildGroupList(List<NotificationItem> items) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return NotificationTile(
          type: item.type,
          title: item.title,
          subtitle: item.subtitle,
          timeAgo: item.timeAgo,
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
