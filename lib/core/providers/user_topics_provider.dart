import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/firestore_repository.dart';

/// Streams the list of topic slugs the current user is following.
/// e.g. ['funding', 'startups', 'ai']
final userTopicsProvider = StreamProvider<List<String>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.read(firestoreRepositoryProvider).watchUserTopics(user.uid);
});
