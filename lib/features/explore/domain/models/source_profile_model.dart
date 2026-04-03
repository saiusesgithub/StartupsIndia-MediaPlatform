import '../../../home/domain/models/news_article.dart';

class SourceProfileModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String bio;
  final String websiteUrl;
  final int followersCount;
  final int followingCount;
  final int newsCount;
  final bool isFollowing;
  final List<NewsArticle> newsArticles;
  final List<NewsArticle> recentArticles;

  const SourceProfileModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.websiteUrl,
    required this.followersCount,
    required this.followingCount,
    required this.newsCount,
    required this.isFollowing,
    required this.newsArticles,
    required this.recentArticles,
  });

  SourceProfileModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? bio,
    String? websiteUrl,
    int? followersCount,
    int? followingCount,
    int? newsCount,
    bool? isFollowing,
    List<NewsArticle>? newsArticles,
    List<NewsArticle>? recentArticles,
  }) {
    return SourceProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      newsCount: newsCount ?? this.newsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      newsArticles: newsArticles ?? this.newsArticles,
      recentArticles: recentArticles ?? this.recentArticles,
    );
  }
}
