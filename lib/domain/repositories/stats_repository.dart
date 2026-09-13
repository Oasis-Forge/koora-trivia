import '../entities/user_stats.dart';

abstract class StatsRepository {
  Future<UserStats> load();
  Future<void> save(UserStats stats);
}
