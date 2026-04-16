import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/style_guide.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../bookmark/presentation/screens/bookmark_screen.dart';
import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../profile/presentation/screens/personal_profile_screen.dart';
import '../../domain/models/news_article.dart';
import 'home_screen.dart';

class MainAppScaffold extends ConsumerStatefulWidget {
  final int initialIndex;
  final List<NewsArticle> bookmarkedArticles;

  const MainAppScaffold({
    super.key,
    this.initialIndex = 0,
    this.bookmarkedArticles = const <NewsArticle>[],
  });

  @override
  ConsumerState<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends ConsumerState<MainAppScaffold> {
  late int _navIndex;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Keep the FCM token in sync while the user is logged in
    ref.watch(fcmTokenSyncProvider);

    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: IndexedStack(
        index: _navIndex,
        children: [
          const HomeScreen(showBottomNav: false),
          const ExploreScreen(),
          BookmarkScreen(
            bookmarkedArticles: widget.bookmarkedArticles,
            onGoHome: () => setState(() => _navIndex = 0),
          ),
          const PersonalProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grayscaleWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primaryDefault,
        unselectedItemColor: AppColors.grayscaleButtonText,
        selectedLabelStyle: AppTypography.textSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.textSmall.copyWith(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_rounded),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: 'Bookmark',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
