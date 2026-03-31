import 'news_article.dart';

/// Hardcoded seed data for development.
/// To swap for Firebase tomorrow, replace [latestArticles] with a stream
/// from Firestore and [trendingArticle] from a top-story collection.
class NewsFeedData {
  static const NewsArticle trendingArticle = NewsArticle(
    id: 'trending_001',
    category: 'Europe',
    headline: 'Russian warship: Moskva sinks in Black Sea',
    sourceName: 'BBC News',
    sourceLogoAsset: 'assets/images/thumb_politics.png',
    thumbnailAsset: 'assets/images/trending_hero.png',
    timeAgo: '4h ago',
  );

  static const List<NewsArticle> latestArticles = [
    NewsArticle(
      id: 'latest_001',
      category: 'Sports',
      headline: 'Champions League: City vs Real Madrid preview as Guardiola targets glory',
      sourceName: 'ESPN',
      sourceLogoAsset: 'assets/images/thumb_sports.png',
      thumbnailAsset: 'assets/images/thumb_sports.png',
      timeAgo: '14m ago',
    ),
    NewsArticle(
      id: 'latest_002',
      category: 'Politics',
      headline: 'G7 leaders agree record package of economic support for Ukraine',
      sourceName: 'Reuters',
      sourceLogoAsset: 'assets/images/thumb_politics.png',
      thumbnailAsset: 'assets/images/thumb_politics.png',
      timeAgo: '1h ago',
    ),
    NewsArticle(
      id: 'latest_003',
      category: 'Technology',
      headline: 'Apple unveils M3 chip architecture with groundbreaking energy efficiency',
      sourceName: 'The Verge',
      sourceLogoAsset: 'assets/images/thumb_tech.png',
      thumbnailAsset: 'assets/images/thumb_tech.png',
      timeAgo: '2h ago',
    ),
    NewsArticle(
      id: 'latest_004',
      category: 'Business',
      headline: 'Global markets rally after Fed signals pause in interest rate hikes',
      sourceName: 'Bloomberg',
      sourceLogoAsset: 'assets/images/thumb_business.png',
      thumbnailAsset: 'assets/images/thumb_business.png',
      timeAgo: '3h ago',
    ),
    NewsArticle(
      id: 'latest_005',
      category: 'Sports',
      headline: 'Djokovic wins record 24th Grand Slam title at Australian Open',
      sourceName: 'ESPN',
      sourceLogoAsset: 'assets/images/thumb_sports.png',
      thumbnailAsset: 'assets/images/thumb_sports.png',
      timeAgo: '5h ago',
    ),
    NewsArticle(
      id: 'latest_006',
      category: 'Technology',
      headline: 'OpenAI announces GPT-5 with multimodal reasoning capabilities',
      sourceName: 'TechCrunch',
      sourceLogoAsset: 'assets/images/thumb_tech.png',
      thumbnailAsset: 'assets/images/thumb_tech.png',
      timeAgo: '6h ago',
    ),
  ];

  static const List<String> categories = [
    'All',
    'Sports',
    'Politics',
    'Business',
    'Health',
    'Travel',
    'Science',
    'Technology',
  ];
}
