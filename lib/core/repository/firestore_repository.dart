import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_article_model.dart';
import '../models/user_model.dart';
import '../providers/firebase_providers.dart';

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
    return _users.doc(uid).set(
      {
        'role': role,
        'interests': interests,
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<List<NewsArticleModel>> watchArticles() {
    return _articles
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<NewsArticleModel>> getLatestNews() {
    return _articles
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NewsArticleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<NewsArticleModel>> getTrendingNews() {
    return getLatestNews().map(
      (items) =>
          items.where((article) => article.isTrending).toList(growable: false),
    );
  }

  Future<NewsArticleModel?> getArticleById(String articleId) async {
    if (articleId.trim().isEmpty) return null;

    final doc = await _articles.doc(articleId).get();
    if (!doc.exists) return null;
    return NewsArticleModel.fromFirestore(doc);
  }

  Stream<List<NewsArticleModel>> getArticlesByAuthor(String authorId) {
    if (authorId.trim().isEmpty) return Stream.value(<NewsArticleModel>[]);

    return getLatestNews().map(
      (items) => items
          .where((article) => article.authorId == authorId)
          .toList(growable: false),
    );
  }

  Stream<List<NewsArticleModel>> getBookmarkedArticles(String userId) {
    if (userId.trim().isEmpty) return Stream.value(<NewsArticleModel>[]);

    return getLatestNews().map(
      (items) => items
          .where((article) => article.bookmarkedBy.contains(userId))
          .map((article) => article.copyWith(isBookmarked: true))
          .toList(growable: false),
    );
  }

  Stream<List<NewsArticleModel>> getLikedArticles(String userId) {
    if (userId.trim().isEmpty) return Stream.value(<NewsArticleModel>[]);

    return getLatestNews().map(
      (items) => items
          .where((article) => article.likedBy.contains(userId))
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
        .orderBy('createdAt', descending: true)
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
      'dmrp1d1tv',
      'startups india upload preset',
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
    return _userTopics.doc(uid).snapshots().map(
          (doc) => List<String>.from(doc.data()?['topics'] as List? ?? []),
        );
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
