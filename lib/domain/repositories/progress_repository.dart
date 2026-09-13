import '../entities/category_progress.dart';

abstract class ProgressRepository {
  /// تقدّم كل التصنيفات، مفتاح الخريطة هو `slug`.
  Future<Map<String, CategoryProgress>> loadAll();

  Future<void> save(CategoryProgress progress);

  Future<void> clear();
}
