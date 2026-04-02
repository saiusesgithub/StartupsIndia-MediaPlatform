import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../../explore/presentation/screens/search_screen.dart';
import 'home_screen.dart';

class MainAppScaffold extends StatefulWidget {
  final int initialIndex;

  const MainAppScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  late int _navIndex;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: IndexedStack(
        index: _navIndex,
        children: const [
          HomeScreen(showBottomNav: false),
          SearchScreen(showBottomNav: false),
          _ComingSoonPage(title: 'Bookmark'),
          _ComingSoonPage(title: 'Profile'),
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

class _ComingSoonPage extends StatelessWidget {
  final String title;

  const _ComingSoonPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title coming soon',
        style: AppTypography.textMedium.copyWith(
          color: AppColors.grayscaleBodyText,
        ),
      ),
    );
  }
}
