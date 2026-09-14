import '../../domain/repositories/backup_repository.dart';
import 'economy_provider.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';
import 'stats_provider.dart';

/// يستورد نسخة احتياطية ثم يعيد تحميل كل المزوّدات من التخزين.
///
/// كل مزوّد يحمل نسخته في الذاكرة ويكتبها كاملة عند أول حفظ. بلا إعادة تحميل
/// كان أول حفظ بعد الاستيراد (قلب يتجدّد كل نصف دقيقة، أو جولة تُلعب) يكتب
/// البيانات القديمة فوق المستوردة، فيضيع الاستيراد بصمت.
class RestoreBackup {
  const RestoreBackup({
    required BackupRepository repository,
    required StatsProvider stats,
    required ProgressProvider progress,
    required EconomyProvider economy,
    required SettingsProvider settings,
  })  : _repository = repository,
        _stats = stats,
        _progress = progress,
        _economy = economy,
        _settings = settings;

  final BackupRepository _repository;
  final StatsProvider _stats;
  final ProgressProvider _progress;
  final EconomyProvider _economy;
  final SettingsProvider _settings;

  /// يعيد `false` إن كان الرمز تالفاً؛ حينها لا يتغيّر شيء.
  Future<bool> call(String code) async {
    if (!await _repository.import(code)) return false;

    // الإعدادات أولاً: تحميل الإحصائيات يُخطر `AppLifecycleHooks` فيعيد جدولة
    // التنبيه، ويجب أن يرى حينها الإعدادات المستوردة لا القديمة. وتحميلها يعيد
    // جدولة التنبيه أو يلغيه بحسب ما استُورد.
    await _settings.init();
    await Future.wait([
      _stats.init(),
      _progress.init(),
      _economy.init(),
    ]);
    return true;
  }
}
