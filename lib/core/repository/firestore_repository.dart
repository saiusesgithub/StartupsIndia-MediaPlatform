import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> saveUser(UserModel user) {
    return _users
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
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
}

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreRepository(firestore);
});
