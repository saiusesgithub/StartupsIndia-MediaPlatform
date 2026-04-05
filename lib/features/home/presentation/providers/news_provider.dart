import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/news_article_model.dart';
import '../../../../core/repository/firestore_repository.dart';

final latestNewsProvider = StreamProvider<List<NewsArticleModel>>((ref) {
  return ref.watch(firestoreRepositoryProvider).getLatestNews();
});

final trendingNewsProvider = StreamProvider<List<NewsArticleModel>>((ref) {
  return ref.watch(firestoreRepositoryProvider).getTrendingNews();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final debouncedSearchQueryProvider = FutureProvider<String>((ref) async {
  final query = ref.watch(searchQueryProvider);

  // Delay by 500ms to debounce
  await Future.delayed(const Duration(milliseconds: 500));

  return query;
});

final searchArticlesProvider = FutureProvider<List<NewsArticleModel>>((
  ref,
) async {
  // Watch the debounced query instead of the raw query
  final debouncedQuery = await ref.watch(debouncedSearchQueryProvider.future);

  if (debouncedQuery.isEmpty) {
    return <NewsArticleModel>[];
  }
  final repository = ref.watch(firestoreRepositoryProvider);
  return repository.searchArticles(debouncedQuery);
});

final searchResultProvider = searchArticlesProvider;
