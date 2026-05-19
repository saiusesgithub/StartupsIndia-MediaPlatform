import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/models/post_model.dart';

final postRepositoryProvider = Provider<PostRepository>(
  (_) => PostRepository(),
);

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(postRepositoryProvider).watchPosts();
});
