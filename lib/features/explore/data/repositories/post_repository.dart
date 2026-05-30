import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/post_model.dart';

const int kInitialPostLimit = 20;
const int kInitialCommentLimit = 100;

class PostRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  CollectionReference<Map<String, dynamic>> get _articles =>
      _firestore.collection('articles');

  // ── Posts feed ────────────────────────────────────────────────────────────

  Stream<List<PostModel>> watchPosts({int limit = kInitialPostLimit}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  // ── Like / Bookmark (posts) ───────────────────────────────────────────────

  Future<void> togglePostLike(String postId, String userId) async {
    final docRef = _posts.doc(postId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(docRef);
      if (!doc.exists) return;
      final likedBy = List<String>.from(doc.data()!['likedBy'] as List? ?? []);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      tx.update(docRef, {'likedBy': likedBy, 'likesCount': likedBy.length});
    });
  }

  Future<void> togglePostBookmark(String postId, String userId) async {
    final docRef = _posts.doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final bookmarkedBy = List<String>.from(
      doc.data()!['bookmarkedBy'] as List? ?? [],
    );
    if (bookmarkedBy.contains(userId)) {
      await docRef.update({
        'bookmarkedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'bookmarkedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  Future<void> incrementPostShareCount(String postId) async {
    await _posts.doc(postId).update({'shareCount': FieldValue.increment(1)});
  }

  // ── Bookmarked posts ──────────────────────────────────────────────────────

  Stream<List<PostModel>> getBookmarkedPosts(
    String userId, {
    int limit = kInitialPostLimit,
  }) {
    return _posts
        .where('bookmarkedBy', arrayContains: userId)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Stream<List<CommentModel>> watchPostComments(
    String postId, {
    int limit = kInitialCommentLimit,
  }) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => CommentModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<CommentModel>> watchArticleComments(
    String articleId, {
    int limit = kInitialCommentLimit,
  }) {
    return _articles
        .doc(articleId)
        .collection('comments')
        .orderBy('createdAt')
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => CommentModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> addPostComment({
    required String postId,
    required String userId,
    required String authorName,
    required String avatarUrl,
    required String content,
  }) async {
    final batch = _firestore.batch();
    final commentRef = _posts.doc(postId).collection('comments').doc();
    batch.set(commentRef, {
      'userId': userId,
      'authorName': authorName,
      'avatarUrl': avatarUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_posts.doc(postId), {
      'commentsCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> addArticleComment({
    required String articleId,
    required String userId,
    required String authorName,
    required String avatarUrl,
    required String content,
  }) async {
    await _articles.doc(articleId).collection('comments').add({
      'userId': userId,
      'authorName': authorName,
      'avatarUrl': avatarUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
