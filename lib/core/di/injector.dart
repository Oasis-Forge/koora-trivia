import 'package:flutter/foundation.dart' show kReleaseMode;

import '../../data/datasources/economy_local_datasource.dart';
import '../../data/datasources/progress_local_datasource.dart';
import '../../data/datasources/question_local_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/datasources/stats_local_datasource.dart';
import '../../data/repositories/backup_repository_impl.dart';
import '../../data/repositories/economy_repository_impl.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/stats_repository_impl.dart';
import '../../data/services/ad_consent.dart';
import '../../data/services/admob_ad_service.dart';
import '../../data/services/local_notification_scheduler.dart';
import '../../data/services/url_link_opener.dart';
import '../../domain/repositories/ad_service.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../domain/repositories/economy_repository.dart';
import '../../domain/repositories/link_opener.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../domain/repositories/reminder_scheduler.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/stats_repository.dart';

/// حاوية بسيطة لربط الطبقات — تُنشأ مرة واحدة عند إقلاع التطبيق.
class Injector {
  Injector()
      : quizRepository = QuizRepositoryImpl(AssetQuestionDataSource()),
        statsRepository = StatsRepositoryImpl(PrefsStatsDataSource()),
        progressRepository = ProgressRepositoryImpl(PrefsProgressDataSource()),
        settingsRepository = SettingsRepositoryImpl(PrefsSettingsDataSource()),
        economyRepository = EconomyRepositoryImpl(PrefsEconomyDataSource()),
        backupRepository = BackupRepositoryImpl(),
        // معرّفات الإنتاج في بناء الإصدار فقط؛ بناء التطوير يبقى على معرّفات
        // الاختبار حمايةً للحساب من النقر على إعلاناتك الحقيقية أثناء التطوير.
        adService = AdMobAdService(
          useTestIds: !kReleaseMode,
          consent: UmpAdConsent(
            // لاختبار نموذج الموافقة كمستخدم أوروبي على المحاكي:
            // flutter run --dart-define=UMP_DEBUG_EEA=true
            debugEea:
                !kReleaseMode && const bool.fromEnvironment('UMP_DEBUG_EEA'),
          ),
        ),
        reminderScheduler = LocalNotificationScheduler(),
        linkOpener = UrlLinkOpener();

  final QuizRepository quizRepository;
  final StatsRepository statsRepository;
  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;
  final EconomyRepository economyRepository;
  final BackupRepository backupRepository;
  final AdService adService;
  final ReminderScheduler reminderScheduler;
  final LinkOpener linkOpener;
}
