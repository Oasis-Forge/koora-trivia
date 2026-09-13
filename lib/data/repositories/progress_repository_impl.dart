import '../../domain/entities/category_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_datasource.dart';
import '../models/progress_model.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._dataSource);

  final ProgressLocalDataSource _dataSource;

  @override
  Future<Map<String, CategoryProgress>> loadAll() async {
    // ⚠️ لا تُعِد خريطة المصدر مباشرة: نوعها وقت التشغيل
    // `Map<String, CategoryProgressModel>`، فتقبلها الترجمة بحكم التغاير لكن
    // أي إسناد لاحق لكيان `CategoryProgress` عادي داخلها يرمي TypeError
    // (وكان يُبتلع داخل شاشة النتيجة فلا تُحفظ النجوم ولا يُفتح المستوى التالي).
    final models = await _dataSource.read();
    return Map<String, CategoryProgress>.from(models);
  }

  @override
  Future<void> save(CategoryProgress progress) =>
      _dataSource.write(CategoryProgressModel.fromEntity(progress));

  @override
  Future<void> clear() => _dataSource.clear();
}
