import '../entities/economy.dart';

abstract class EconomyRepository {
  Future<Economy> load();
  Future<void> save(Economy economy);
}
