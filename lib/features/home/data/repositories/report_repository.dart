import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ReportReason { spam, misinformation, harassment, other }

extension ReportReasonX on ReportReason {
  String get label => switch (this) {
        ReportReason.spam => 'Spam or ads',
        ReportReason.misinformation => 'False information',
        ReportReason.harassment => 'Hateful or abusive',
        ReportReason.other => 'Something else',
      };
}

class ReportRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> reportArticle({
    required String articleId,
    required ReportReason reason,
  }) async {
    final uid = _requireUid();

    final dupe = await _db
        .collection('reports')
        .where('type', isEqualTo: 'article')
        .where('targetId', isEqualTo: articleId)
        .where('reportedBy', isEqualTo: uid)
        .limit(1)
        .get();

    if (dupe.docs.isNotEmpty) throw const _AlreadyReportedError();

    await _db.collection('reports').add({
      'type': 'article',
      'targetId': articleId,
      'articleId': articleId,
      'reportedBy': uid,
      'reason': reason.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportComment({
    required String commentId,
    required String articleId,
    required ReportReason reason,
  }) async {
    final uid = _requireUid();

    final dupe = await _db
        .collection('reports')
        .where('type', isEqualTo: 'comment')
        .where('targetId', isEqualTo: commentId)
        .where('reportedBy', isEqualTo: uid)
        .limit(1)
        .get();

    if (dupe.docs.isNotEmpty) throw const _AlreadyReportedError();

    await _db.collection('reports').add({
      'type': 'comment',
      'targetId': commentId,
      'articleId': articleId,
      'reportedBy': uid,
      'reason': reason.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    return uid;
  }
}

class _AlreadyReportedError implements Exception {
  const _AlreadyReportedError();
}

bool isAlreadyReported(Object e) => e is _AlreadyReportedError;
