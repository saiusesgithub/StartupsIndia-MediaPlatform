import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/leaderboard_repository.dart';
import '../../domain/models/startup_leader_entry.dart';

final leaderboardRepositoryProvider = Provider((_) => LeaderboardRepository());

final leaderboardProvider =
    FutureProvider.autoDispose<List<StartupLeaderEntry>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).fetchLeaderboard();
});
