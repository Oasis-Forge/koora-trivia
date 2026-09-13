import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/utils/arabic_count.dart';
import 'package:football_trivia/data/services/local_notification_scheduler.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/reminder_plan.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/settings_repository.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([this.settings = const AppSettings()]);

  AppSettings settings;
  int saveCount = 0;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings value) async {
    settings = value;
    saveCount++;
  }
}

class _FakeScheduler implements ReminderScheduler {
  _FakeScheduler({
    this.permissionGranted = true,
    this.alreadyHasPermission = false,
  });

  bool permissionGranted;
  bool alreadyHasPermission;

  final scheduled = <List<ReminderPlan>>[];
  int cancelCount = 0;
  int permissionRequests = 0;

  int get scheduleCount => scheduled.length;
  ReminderPlan get firstPlan => scheduled.last.first;

  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => alreadyHasPermission;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (permissionGranted) alreadyHasPermission = true;
    return permissionGranted;
  }

  @override
  Future<void> schedule(List<ReminderPlan> plans) async => scheduled.add(plans);

  @override
  Future<void> cancelAll() async => cancelCount++;
}

/// صباح يوم عادي — قبل موعد التنبيه الافتراضي (20:00).
final _morning = DateTime(2026, 9, 13, 10);

/// إحصائيات لاعب أنهى تحدي [dayKey] وسلسلته [streak].
UserStats _doneOn(String dayKey, int streak) =>
    UserStats(currentStreak: streak, lastDailyDayKey: dayKey);

SettingsProvider _provider(
  _FakeSettingsRepository repo,
  _FakeScheduler scheduler, {
  DateTime Function()? clock,
}) =>
    SettingsProvider(
      repository: repo,
      scheduler: scheduler,
      clock: clock ?? () => _morning,
    );

void main() {
  group('SettingsProvider — التنبيه', () {
    test('التشغيل يطلب الإذن ويجدول تنبيهات الأيام القادمة', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler();
      final provider = _provider(repo, scheduler);

      await provider.init();
      final ok = await provider.setReminderEnabled(true);

      expect(ok, isTrue);
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduleCount, 1);
      expect(scheduler.scheduled.last, hasLength(AppConfig.reminderDaysAhead));
      expect(scheduler.firstPlan.at, DateTime(2026, 9, 13, 20));
      expect(provider.reminderEnabled, isTrue);
      expect(repo.settings.reminderEnabled, isTrue);
    });

    test('رفض الإذن يترك التنبيه مطفأً ولا يجدول شيئاً', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler(permissionGranted: false);
      final provider = _provider(repo, scheduler);

      await provider.init();
      final ok = await provider.setReminderEnabled(true);

      expect(ok, isFalse);
      expect(provider.reminderEnabled, isFalse);
      expect(provider.permissionDenied, isTrue);
      expect(scheduler.scheduleCount, 0);
      expect(repo.settings.reminderEnabled, isFalse);
    });

    test('الإيقاف يلغي التنبيهات المجدولة', () async {
      final repo = _FakeSettingsRepository(
        const AppSettings(reminderEnabled: true),
      );
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider = _provider(repo, scheduler);

      await provider.init();
      await provider.setReminderEnabled(false);

      expect(provider.reminderEnabled, isFalse);
      expect(scheduler.cancelCount, greaterThan(0));
      expect(repo.settings.reminderEnabled, isFalse);
    });

    test('تغيير الوقت يعيد الجدولة عند التشغيل فقط', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider = _provider(repo, scheduler);

      await provider.init();

      // مطفأ: يُحفظ الوقت دون جدولة.
      await provider.setReminderTime(hour: 9, minute: 30);
      expect(scheduler.scheduleCount, 0);
      expect(provider.reminderLabel, '09:30');

      await provider.setReminderEnabled(true);
      final afterEnable = scheduler.scheduleCount;

      await provider.setReminderTime(hour: 21, minute: 15);
      expect(scheduler.scheduleCount, afterEnable + 1);
      expect(scheduler.firstPlan.at, DateTime(2026, 9, 13, 21, 15));
    });

    test('سحب الإذن من إعدادات النظام يُطفئ التنبيه ويلغيه عند الإقلاع',
        () async {
      // المستخدم فعّل التنبيه سابقاً ثم منع الإشعارات من النظام.
      final repo = _FakeSettingsRepository(
        const AppSettings(reminderEnabled: true, reminderHour: 19),
      );
      final scheduler = _FakeScheduler(alreadyHasPermission: false);
      final provider = _provider(repo, scheduler);

      await provider.init();

      expect(provider.reminderEnabled, isFalse);
      expect(scheduler.scheduleCount, 0);
      expect(scheduler.cancelCount, 1);
      expect(repo.settings.reminderEnabled, isFalse);
    });

    test('الإذن الممنوح مسبقاً لا يُطلب مجدداً', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider = _provider(repo, scheduler);

      await provider.init();
      await provider.setReminderEnabled(true);

      expect(scheduler.permissionRequests, 0);
      expect(scheduler.scheduleCount, 1);
    });

    test('الإقلاع يعيد الجدولة دائماً', () async {
      final repo = _FakeSettingsRepository(
        const AppSettings(reminderEnabled: true),
      );
      final scheduler = _FakeScheduler(alreadyHasPermission: true);

      await _provider(repo, scheduler).init();

      expect(scheduler.scheduleCount, 1);
    });
  });

  group('مزامنة التنبيه مع تحدي اليوم', () {
    Future<(SettingsProvider, _FakeScheduler)> enabled({
      DateTime Function()? clock,
    }) async {
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider = _provider(
        _FakeSettingsRepository(const AppSettings(reminderEnabled: true)),
        scheduler,
        clock: clock,
      );
      await provider.init();
      return (provider, scheduler);
    }

    test('إنجاز تحدي اليوم ينقل أول تنبيه إلى الغد ويذكر السلسلة', () async {
      final (provider, scheduler) = await enabled();
      expect(scheduler.firstPlan.at, DateTime(2026, 9, 13, 20));

      await provider.syncReminder(_doneOn('2026-09-13', 4));

      expect(scheduler.scheduleCount, 2);
      expect(scheduler.firstPlan.at, DateTime(2026, 9, 14, 20));
      expect(scheduler.firstPlan.streak, 4);
    });

    test('مزامنة بلا تغيير لا تعيد الجدولة', () async {
      final (provider, scheduler) = await enabled();

      await provider.syncReminder(const UserStats());
      await provider.syncReminder(const UserStats());
      expect(scheduler.scheduleCount, 1);

      // سلسلة قائمة منذ الأمس تدخل نص تنبيه اليوم.
      await provider.syncReminder(_doneOn('2026-09-12', 3));
      expect(scheduler.scheduleCount, 2);
      expect(scheduler.firstPlan.streak, 3);
    });

    test('سلسلة انقطعت لا تُذكر', () async {
      final (provider, scheduler) = await enabled();

      await provider.syncReminder(_doneOn('2026-09-10', 8));

      expect(scheduler.firstPlan.streak, isNull);
    });

    test('المزامنة والتنبيه مطفأ لا تجدول شيئاً', () async {
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider = _provider(_FakeSettingsRepository(), scheduler);
      await provider.init();

      await provider.syncReminder(_doneOn('2026-09-13', 2));

      expect(scheduler.scheduleCount, 0);
    });

    test('حالة التحدي المعروفة قبل التشغيل تدخل أول جدولة', () async {
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider = _provider(_FakeSettingsRepository(), scheduler);
      await provider.init();

      await provider.syncReminder(_doneOn('2026-09-13', 6));
      await provider.setReminderEnabled(true);

      expect(scheduler.firstPlan.at, DateTime(2026, 9, 14, 20));
      expect(scheduler.firstPlan.streak, 6);
    });

    test('بعد منتصف الليل لا يُعامَل اليوم الجديد كأنه أُنجز', () async {
      var now = _morning;
      final (provider, scheduler) = await enabled(clock: () => now);
      await provider.syncReminder(_doneOn('2026-09-13', 4));
      expect(scheduler.firstPlan.at, DateTime(2026, 9, 14, 20));

      // التطبيق بقي مفتوحاً بعد منتصف الليل دون أي مزامنة جديدة.
      now = DateTime(2026, 9, 14, 0, 30);
      await provider.setReminderTime(hour: 20, minute: 0);

      expect(scheduler.firstPlan.at, DateTime(2026, 9, 14, 20));
      expect(scheduler.firstPlan.streak, 4);
    });
  });

  group('نص التنبيه', () {
    final questions = ArabicCount.format(
      AppConfig.dailyQuestionCount,
      ArabicNoun.question,
    );

    test('يذكر السلسلة بصيغتها الصحيحة وعدد أسئلة التحدي', () {
      final body = LocalNotificationScheduler.bodyFor(
        ReminderPlan(at: _morning, streak: 5),
      );

      expect(body, contains('5 أيام'));
      expect(body, contains(questions));
    });

    test('بلا سلسلة: نص عام لا يَعِد بسلسلة', () {
      final body = LocalNotificationScheduler.bodyFor(
        ReminderPlan(at: _morning),
      );

      expect(body, isNot(contains('سلسل')));
      expect(body, contains(questions));
    });

    test('عدد الأسئلة من الإعدادات لا من نص ثابت', () {
      final body = LocalNotificationScheduler.bodyFor(
        ReminderPlan(at: _morning),
      );

      expect(body, isNot(contains('سبعة')));
    });
  });
}
