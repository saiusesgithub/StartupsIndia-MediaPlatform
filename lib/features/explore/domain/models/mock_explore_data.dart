import '../../../home/domain/models/news_article.dart';
import '../../../home/domain/models/news_feed_data.dart';

class TopicSearchItem {
  final String id;
  final String title;
  final String description;
  final String thumbnailAsset;

  const TopicSearchItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailAsset,
  });
}

class AuthorItem {
  final String id;
  final String name;
  final String followers;
  final String avatarAsset;

  const AuthorItem({
    required this.id,
    required this.name,
    required this.followers,
    required this.avatarAsset,
  });
}

class MockExploreData {
  static final List<NewsArticle> news = [
    ...NewsFeedData.latestArticles,
    NewsFeedData.trendingArticle,
  ];

  static const List<TopicSearchItem> topics = [
    TopicSearchItem(
      id: 'topic_1',
      title: 'Technology',
      description: 'AI, apps, devices and startup ecosystem updates.',
      thumbnailAsset: 'assets/images/thumb_tech.png',
    ),
    TopicSearchItem(
      id: 'topic_2',
      title: 'Business',
      description: 'Markets, venture funding and global business news.',
      thumbnailAsset: 'assets/images/thumb_business.png',
    ),
    TopicSearchItem(
      id: 'topic_3',
      title: 'Sports',
      description: 'Match reports, previews and athlete interviews.',
      thumbnailAsset: 'assets/images/thumb_sports.png',
    ),
  ];

  static const List<AuthorItem> authors = [
    AuthorItem(
      id: 'author_1',
      name: 'Samantha Reed',
      followers: '1.2M followers',
      avatarAsset: 'assets/images/thumb_politics.png',
    ),
    AuthorItem(
      id: 'author_2',
      name: 'Michael Tan',
      followers: '860K followers',
      avatarAsset: 'assets/images/thumb_tech.png',
    ),
    AuthorItem(
      id: 'author_3',
      name: 'Aarav Sharma',
      followers: '540K followers',
      avatarAsset: 'assets/images/thumb_business.png',
    ),
  ];
}
