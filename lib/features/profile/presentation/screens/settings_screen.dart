import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/models/news_article_model.dart';
import '../../../../core/repository/firestore_repository.dart';
import '../../../../core/providers/theme_service_provider.dart';
import '../../../../theme/style_guide.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeServiceProvider);
    final bool isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTypography.textMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          _settingsTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notification',
            onTap: () {},
          ),
          _settingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Security',
            onTap: () {},
          ),
          _settingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Help',
            onTap: () {},
          ),
          _settingsTile(
            context,
            icon: Icons.cloud_upload_outlined,
            title: 'Seed Sample Articles (Dev)',
            onTap: () => _seedSampleArticles(context, ref),
          ),
          SwitchListTile(
            value: isDark,
            onChanged: (value) {
              ref.read(themeServiceProvider.notifier).setDarkMode(value);
            },
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(
              'Dark Mode',
              style: AppTypography.textMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            activeColor: AppColors.primaryDefault,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: Text(
              'Logout',
              style: AppTypography.textMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: AppTypography.textMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ref.read(authRepositoryProvider).signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _seedSampleArticles(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(firestoreRepositoryProvider);
      final now = DateTime.now();

      final samples = <NewsArticleModel>[
        NewsArticleModel(
          id: 'dev_${now.millisecondsSinceEpoch}_1',
          createdAt: now.subtract(const Duration(minutes: 3)),
          authorId: 'demo_user',
          category: 'Technology',
          headline: 'AI funding in India startups jumps 38% in Q1',
          sourceName: 'TechCrunch',
          sourceId: 'techcrunch',
          sourceLogoAsset: 'assets/images/thumb_tech.png',
          thumbnailAsset: 'assets/images/thumb_tech.png',
          timeAgo: '3m ago',
          body: 'Seed article body for Firestore smoke test.',
          likesCount: 42,
          commentsCount: 8,
          isTrending: true,
        ),
        NewsArticleModel(
          id: 'dev_${now.millisecondsSinceEpoch}_2',
          createdAt: now.subtract(const Duration(minutes: 12)),
          authorId: 'demo_user',
          category: 'Business',
          headline: 'Karnataka unveils new startup policy incentives',
          sourceName: 'Bloomberg',
          sourceId: 'bloomberg',
          sourceLogoAsset: 'assets/images/thumb_business.png',
          thumbnailAsset: 'assets/images/thumb_business.png',
          timeAgo: '12m ago',
          body: 'Seed article body for Firestore smoke test.',
          likesCount: 16,
          commentsCount: 3,
          isTrending: true,
        ),
        NewsArticleModel(
          id: 'dev_${now.millisecondsSinceEpoch}_3',
          createdAt: now.subtract(const Duration(minutes: 29)),
          authorId: 'external_001',
          category: 'Politics',
          headline: 'State-backed innovation grants open for applications',
          sourceName: 'Reuters',
          sourceId: 'reuters',
          sourceLogoAsset: 'assets/images/thumb_politics.png',
          thumbnailAsset: 'assets/images/thumb_politics.png',
          timeAgo: '29m ago',
          body: 'Seed article body for Firestore smoke test.',
          likesCount: 11,
          commentsCount: 2,
          isTrending: false,
        ),
        NewsArticleModel(
          id: 'dev_${now.millisecondsSinceEpoch}_4',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
          authorId: 'external_002',
          category: 'Sports',
          headline: 'Startup-sponsored marathon in Bengaluru sets records',
          sourceName: 'ESPN',
          sourceId: 'espn',
          sourceLogoAsset: 'assets/images/thumb_sports.png',
          thumbnailAsset: 'assets/images/thumb_sports.png',
          timeAgo: '1h ago',
          body: 'Seed article body for Firestore smoke test.',
          likesCount: 7,
          commentsCount: 1,
          isTrending: false,
        ),
      ];

      for (final article in samples) {
        await repo.saveArticle(article);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample articles uploaded to Firestore.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
    }
  }
}
