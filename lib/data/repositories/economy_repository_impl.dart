import '../../domain/entities/economy.dart';
import '../../domain/repositories/economy_repository.dart';
import '../datasources/economy_local_datasource.dart';

class EconomyRepositoryImpl implements EconomyRepository {
  EconomyRepositoryImpl(this._dataSource);

  final EconomyLocalDataSource _dataSource;

  @override
  Future<Economy> load() => _dataSource.read();

  @override
  Future<void> save(Economy economy) => _dataSource.write(economy);
}
