import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/stats_local_datasource.dart';
import '../models/user_stats_model.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._dataSource);

  final StatsLocalDataSource _dataSource;

  @override
  Future<UserStats> load() => _dataSource.read();

  @override
  Future<void> save(UserStats stats) =>
      _dataSource.write(UserStatsModel.fromEntity(stats));
}
