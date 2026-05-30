import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/news_article_model.dart';
import '../models/user_model.dart';
import '../providers/firebase_providers.dart';

const int kInitialArticleLimit = 20;

class ArticlePage {
  final List<NewsArticleModel> articles;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const ArticlePage({
    required this.articles,
    required this.lastDocument,
    required this.hasMore,
  });
}

class FirestoreRepository {
  FirestoreRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _articles =>
      _firestore.collection('articles');

  CollectionReference<Map<String, dynamic>> get _userTopics =>
      _firestore.collection('user_topics');

  Future<void> saveUser(UserModel user) {
    return _users
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Persists the role + interests chosen during onboarding and marks the
  /// account as fully onboarded. Uses merge so existing profile fields are
  /// never overwritten.
  Future<void> saveUserOnboarding({
    required String uid,
    required String role,
    required List<String> interests,
  }) {
    return _users.doc(uid).set({
      'role': role,
      'interests': interests,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<bool> isUsernameAvailable(String username, String currentUid) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final snap = await _users
        .where('usernameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return true;
    return snap.docs.first.id == currentUid;
  }

  Query<Map<String, dynamic>> _articleOrderQuery() {
    return _articles.orderBy('updatedAt', descending: true);
  }

  Query<Map<String, dynamic>> _latestArticlesQuery() {
    return _articleOrderQuery();
  }

  Query<Map<String, dynamic>> _trendingArticlesQuery() {
    return _articleOrderQuery().where('isTrending', isEqualTo: true);
  }

  List<String> _categoryVariants(String category) {
    final raw = category.trim();
    final lower = raw.toLowerCase();
    final titleCase = lower.isEmpty
        ? lower
        : '${lower[0].toUpperCase()}${lower.substring(1)}';
    return <String>{
      raw,
      lower,
      lower.toUpperCase(),
      titleCase,
    }.where((value) => value.isNotEmpty).toList(growable: false);
  }

  Query<Map<String, dynamic>> _categoryArticlesQuery(String category) {
    final variants = _categoryVariants(category);
    return _articles.where('category', whereIn: variants);
  }

  Query<Map<String, dynamic>> _queryForCategory(String category) {
    final normalized = category.trim().toLowerCase();
    return normalized.isEmpty
        ? _latestArticlesQuery()
        : _categoryArticlesQuery(normalized);
  }

  Future<ArticlePage> _fetchArticlePage(
    Query<Map<String, dynamic>> query, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = kInitialArticleLimit,
  }) async {
    final pageSize = limit <= 0 ? kInitialArticleLimit : limit;
    var pageQuery = query.limit(pageSize);
    if (startAfter != null) {
      pageQuery = pageQuery.startAfterDocument(startAfter);
    }

    final snapshot = await pageQuery.get();
    final articles = snapshot.docs
        .map(NewsArticleModel.fromFirestore)
        .toList(growable: false);

    return ArticlePage(
      articles: articles,
      lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  Stream<List<NewsArticleModel>> watchArticles({
    int limit = kInitialArticleLimit,
  }) {
    return _latestArticlesQuery()
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<NewsArticleModel>> getLatestNews({
    int limit = kInitialArticleLimit,
  }) {
    return _latestArticlesQuery()
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<ArticlePage> fetchLatestNewsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = kInitialArticleLimit,
  }) {
    return _fetchArticlePage(
      _latestArticlesQuery(),
      startAfter: startAfter,
      limit: limit,
    );
  }

  Stream<List<NewsArticleModel>> getTrendingNews({
    int limit = kInitialArticleLimit,
  }) {
    return _trendingArticlesQuery()
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<ArticlePage> fetchTrendingNewsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = kInitialArticleLimit,
  }) {
    return _fetchArticlePage(
      _trendingArticlesQuery(),
      startAfter: startAfter,
      limit: limit,
    );
  }

  Stream<List<NewsArticleModel>> getNewsByCategory(
    String category, {
    int limit = kInitialArticleLimit,
  }) {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) {
      // All-articles query: server-side orderBy is safe here (no category filter).
      return _latestArticlesQuery()
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(NewsArticleModel.fromFirestore)
                .toList(growable: false),
          );
    }
    // Category filter without orderBy avoids the composite-index requirement.
    // We sort client-side instead.
    final variants = _categoryVariants(normalized);
    return _articles
        .where('category', whereIn: variants)
        .limit(limit * 3)
        .snapshots()
        .map((snapshot) {
          final articles = snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList();
          articles.sort((a, b) {
            final aTime = a.createdAt ?? DateTime(0);
            final bTime = b.createdAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
          return articles.take(limit).toList(growable: false);
        });
  }

  Future<ArticlePage> fetchNewsByCategoryPage(
    String category, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = kInitialArticleLimit,
  }) {
    return _fetchArticlePage(
      _queryForCategory(category),
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<void> incrementViewCount(String articleId) async {
    try {
      await _articles.doc(articleId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<NewsArticleModel?> getArticleById(String articleId) async {
    if (articleId.trim().isEmpty) return null;

    final doc = await _articles.doc(articleId).get();
    if (!doc.exists) return null;
    return NewsArticleModel.fromFirestore(doc);
  }

  Stream<List<NewsArticleModel>> getArticlesByAuthor(String authorId) {
    if (authorId.trim().isEmpty) return Stream.value(<NewsArticleModel>[]);

    return _articleOrderQuery()
        .where('authorId', isEqualTo: authorId)
        .limit(kInitialArticleLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<NewsArticleModel>> getBookmarkedArticles(String userId) {
    if (userId.trim().isEmpty) return Stream.value(<NewsArticleModel>[]);

    return _articleOrderQuery()
        .where('bookmarkedBy', arrayContains: userId)
        .limit(kInitialArticleLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .map((article) => article.copyWith(isBookmarked: true))
              .toList(growable: false),
        );
  }

  Stream<List<NewsArticleModel>> getLikedArticles(String userId) {
    if (userId.trim().isEmpty) return Stream.value(<NewsArticleModel>[]);

    return _articleOrderQuery()
        .where('likedBy', arrayContains: userId)
        .limit(kInitialArticleLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .map((article) => article.copyWith(isLiked: true))
              .toList(growable: false),
        );
  }

  Future<List<NewsArticleModel>> searchArticles(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return <NewsArticleModel>[];
    }

    final snapshot = await _articles
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();

    final articles = snapshot.docs
        .map(NewsArticleModel.fromFirestore)
        .toList(growable: false);

    return articles
        .where((article) {
          final headline = article.headline.toLowerCase();
          final sourceName = article.sourceName.toLowerCase();
          final category = article.category.toLowerCase();
          return headline.contains(normalizedQuery) ||
              sourceName.contains(normalizedQuery) ||
              category.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Future<void> saveArticle(NewsArticleModel article) {
    return _articles
        .doc(article.id)
        .set(article.toFirestore(), SetOptions(merge: true));
  }

  Future<String> uploadImage(String imagePath) async {
    final cloudinary = CloudinaryPublic(
      AppConfig.cloudinaryCloudName,
      AppConfig.cloudinaryUploadPreset,
      cache: false,
    );

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(imagePath),
    );

    return response.secureUrl;
  }

  Future<void> createArticle(NewsArticleModel article) async {
    final docId = article.id.trim().isEmpty ? _articles.doc().id : article.id;
    await _articles
        .doc(docId)
        .set(article.toFirestore(), SetOptions(merge: true));
  }

  // ── user_topics ──────────────────────────────────────────────────────────

  Stream<List<String>> watchUserTopics(String uid) {
    return _userTopics
        .doc(uid)
        .snapshots()
        .map((doc) => List<String>.from(doc.data()?['topics'] as List? ?? []));
  }

  Future<void> followTopic(String uid, String topic) {
    return _userTopics.doc(uid).set({
      'topics': FieldValue.arrayUnion([topic]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unfollowTopic(String uid, String topic) {
    return _userTopics.doc(uid).set({
      'topics': FieldValue.arrayRemove([topic]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── likes ─────────────────────────────────────────────────────────────────

  Future<void> toggleLike(String articleId, String userId) async {
    final docRef = _articles.doc(articleId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data() ?? <String, dynamic>{};
      final likedBy = List<String>.from(data['likedBy'] as List? ?? []);
      final alreadyLiked = likedBy.contains(userId);

      if (alreadyLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(docRef, {
        'likedBy': likedBy,
        'likesCount': likedBy.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> toggleBookmark(String articleId, String userId) async {
    final doc = await _articles.doc(articleId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? <String, dynamic>{};
    final bookmarkedBy = List<String>.from(data['bookmarkedBy'] as List? ?? []);
    if (bookmarkedBy.contains(userId)) {
      // Remove bookmark
      await _articles.doc(articleId).update({
        'bookmarkedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Add bookmark
      await _articles.doc(articleId).update({
        'bookmarkedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }
}

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreRepository(firestore);
});
