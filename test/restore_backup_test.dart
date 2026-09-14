import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/datasources/economy_local_datasource.dart';
import 'package:football_trivia/data/datasources/progress_local_datasource.dart';
import 'package:football_trivia/data/datasources/settings_local_datasource.dart';
import 'package:football_trivia/data/datasources/stats_local_datasource.dart';
import 'package:football_trivia/data/repositories/backup_repository_impl.dart';
import 'package:football_trivia/data/repositories/economy_repository_impl.dart';
import 'package:football_trivia/data/repositories/progress_repository_impl.dart';
import 'package:football_trivia/data/repositories/settings_repository_impl.dart';
import 'package:football_trivia/data/repositories/stats_repository_impl.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/domain/entities/reminder_plan.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/restore_backup.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_repositories.dart';

/// تخزين الجهاز القديم: تقدّم يستحق النقل.
final _oldDevice = <String, Object>{
  'user_stats_v1': json.encode({
    'currentStreak': 7,
    'bestStreak': 9,
    'bestScore': 1450,
    'totalScore': 9000,
    'gamesPlayed': 31,
  }),
  'level_progress_v1': json.encode({
    'version': 1,
    'categories': {
      'world_cup': [3, 3, 2],
    },
  }),
  'economy_v1': json.encode({'hearts': 3, 'coins': 420}),
  'app_settings_v1': json.encode({
    'onboardingSeen': true,
    'soundEnabled': false,
    'reminderHour': 9,
  }),
};

/// الجهاز الجديد قبل الاستيراد: لاعب بدأ للتو.
final _newDevice = <String, Object>{
  'economy_v1': json.encode({'hearts': 5, 'coins': 10}),
  'app_settings_v1': json.encode({'onboardingSeen': true}),
};

/// يسجّل ترتيب الجدولة والإلغاء.
class _RecordingScheduler implements ReminderScheduler {
  final events = <String>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<ReminderPlan> plans) async =>
      events.add('schedule');

  @override
  Future<void> cancelAll() async => events.add('cancel');
}

/// المزوّدات الحقيقية فوق التخزين الحقيقي، كما يربطها التطبيق.
class _App {
  _App([ReminderScheduler? scheduler])
      : settings = SettingsProvider(
          repository: SettingsRepositoryImpl(PrefsSettingsDataSource()),
          scheduler: scheduler ?? FakeScheduler(),
        );

  final backup = BackupRepositoryImpl();
  final stats = StatsProvider(
    repository: StatsRepositoryImpl(PrefsStatsDataSource()),
  );
  final progress = ProgressProvider(
    repository: ProgressRepositoryImpl(PrefsProgressDataSource()),
  );
  final economy = EconomyProvider(
    repository: EconomyRepositoryImpl(PrefsEconomyDataSource()),
  );
  final SettingsProvider settings;

  late final restore = RestoreBackup(
    repository: backup,
    stats: stats,
    progress: progress,
    economy: economy,
    settings: settings,
  );

  static Future<_App> launch([ReminderScheduler? scheduler]) async {
    final app = _App(scheduler);
    await app.stats.init();
    await app.progress.init();
    await app.economy.init();
    await app.settings.init();
    return app;
  }
}

Future<String> _exportFromOldDevice() async {
  SharedPreferences.setMockInitialValues(_oldDevice);
  return BackupRepositoryImpl().export();
}

Future<Map<String, dynamic>> _stored(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return json.decode(prefs.getString(key)!) as Map<String, dynamic>;
}

QuizResult _perfectLevel(String slug, int level) => QuizResult(
      answers: [
        for (var i = 0; i < 10; i++)
          AnswerRecord(
            question: Question(
              id: i,
              category: slug,
              categoryName: 'كأس العالم',
              level: level,
              text: 'سؤال $i',
              options: const ['أ', 'ب', 'ج', 'د'],
              answerIndex: 0,
            ),
            selectedIndex: 0,
            earnedPoints: 100,
            secondsLeft: 10,
          ),
      ],
      score: 1000,
      isDaily: false,
      playedAt: DateTime.now(),
      categorySlug: slug,
      level: level,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('الاستيراد يظهر فوراً ويبقى بعد أول حفظ من كل مزوّد', () async {
    final code = await _exportFromOldDevice();
    SharedPreferences.setMockInitialValues(_newDevice);
    final app = await _App.launch();
    expect(app.economy.coins, 10);

    expect(await app.restore(code), isTrue);

    // دون إعادة تشغيل التطبيق.
    expect(app.economy.coins, 420);
    expect(app.stats.stats.gamesPlayed, 31);
    expect(app.progress.starsFor('world_cup', 3), 2);
    expect(app.settings.soundEnabled, isFalse);

    // أول حفظ من كل مزوّد كان يكتب نسخته القديمة فوق المستورد.
    await app.economy.grantRewardedCoins();
    await app.stats.recordResult(
      QuizResult(
        answers: const [],
        score: 100,
        isDaily: false,
        playedAt: DateTime.now(),
      ),
    );
    await app.progress.recordLevelResult(_perfectLevel('world_cup', 3));
    await app.settings.setHapticsEnabled(false);

    expect((await _stored('economy_v1'))['coins'], 420 + 70);

    final stats = await _stored('user_stats_v1');
    expect(stats['gamesPlayed'], 32);
    expect(stats['bestScore'], 1450);
    expect(stats['currentStreak'], 7);

    final progress = await _stored('level_progress_v1');
    expect(
      (progress['categories'] as Map<String, dynamic>)['world_cup'],
      [3, 3, 3, 0, 0, 0, 0, 0, 0, 0],
    );

    final settings = await _stored('app_settings_v1');
    expect(settings['soundEnabled'], isFalse);
    expect(settings['reminderHour'], 9);
    expect(settings['hapticsEnabled'], isFalse);
  });

  test('بلا إعادة تحميل يضيع الاستيراد عند أول حفظ — سبب وجود RestoreBackup',
      () async {
    final code = await _exportFromOldDevice();
    SharedPreferences.setMockInitialValues(_newDevice);
    final app = await _App.launch();

    expect(await app.backup.import(code), isTrue);
    await app.economy.grantRewardedCoins();

    expect((await _stored('economy_v1'))['coins'], 10 + 70);
  });

  test('نسخة التنبيه فيها مطفأ تلغي تنبيهات الجهاز ولا يعيد شيء جدولتها',
      () async {
    // سلسلة قائمة اليوم: تغيّر خطة التنبيه، فتُكشف أي جدولة بالإعدادات القديمة.
    SharedPreferences.setMockInitialValues({
      'user_stats_v1': json.encode({
        'currentStreak': 4,
        'lastDailyDayKey': DayKey.today(),
      }),
      'app_settings_v1': json.encode({
        'onboardingSeen': true,
        'reminderEnabled': false,
      }),
    });
    final code = await BackupRepositoryImpl().export();

    SharedPreferences.setMockInitialValues({
      'app_settings_v1': json.encode({
        'onboardingSeen': true,
        'reminderEnabled': true,
      }),
    });
    final scheduler = _RecordingScheduler();
    final app = await _App.launch(scheduler);
    expect(scheduler.events, ['schedule']);

    // كما يفعل AppLifecycleHooks: كل تغيّر في الإحصائيات يزامن التنبيه.
    app.stats.addListener(() => app.settings.syncReminder(app.stats.stats));
    scheduler.events.clear();

    expect(await app.restore(code), isTrue);
    await pumpEventQueue();

    expect(app.settings.reminderEnabled, isFalse);
    expect(scheduler.events, ['cancel']);
  });

  test('رمز تالف لا يغيّر شيئاً', () async {
    SharedPreferences.setMockInitialValues(_newDevice);
    final app = await _App.launch();

    expect(await app.restore('ليس رمزاً'), isFalse);

    expect(app.economy.coins, 10);
    expect((await _stored('economy_v1'))['coins'], 10);
  });
}
