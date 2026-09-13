import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/services/local_notification_scheduler.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/settings_repository.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  _FakeScheduler({this.permissionGranted = true, this.alreadyHasPermission = false});

  bool permissionGranted;
  bool alreadyHasPermission;

  int scheduleCount = 0;
  int cancelCount = 0;
  int permissionRequests = 0;
  int? lastHour;
  int? lastMinute;

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
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    scheduleCount++;
    lastHour = hour;
    lastMinute = minute;
  }

  @override
  Future<void> cancelDaily() async => cancelCount++;
}

void main() {
  group('SettingsProvider — التنبيه', () {
    test('التشغيل يطلب الإذن ويجدول التنبيه', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler();
      final provider =
          SettingsProvider(repository: repo, scheduler: scheduler);

      await provider.init();
      final ok = await provider.setReminderEnabled(true);

      expect(ok, isTrue);
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduleCount, 1);
      expect(scheduler.lastHour, 20);
      expect(provider.reminderEnabled, isTrue);
      expect(repo.settings.reminderEnabled, isTrue);
    });

    test('رفض الإذن يترك التنبيه مطفأً ولا يجدول شيئاً', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler(permissionGranted: false);
      final provider =
          SettingsProvider(repository: repo, scheduler: scheduler);

      await provider.init();
      final ok = await provider.setReminderEnabled(true);

      expect(ok, isFalse);
      expect(provider.reminderEnabled, isFalse);
      expect(provider.permissionDenied, isTrue);
      expect(scheduler.scheduleCount, 0);
      expect(repo.settings.reminderEnabled, isFalse);
    });

    test('الإيقاف يلغي التنبيه المجدول', () async {
      final repo = _FakeSettingsRepository(
        const AppSettings(reminderEnabled: true),
      );
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider =
          SettingsProvider(repository: repo, scheduler: scheduler);

      await provider.init();
      await provider.setReminderEnabled(false);

      expect(provider.reminderEnabled, isFalse);
      expect(scheduler.cancelCount, greaterThan(0));
      expect(repo.settings.reminderEnabled, isFalse);
    });

    test('تغيير الوقت يعيد الجدولة عند التشغيل فقط', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider =
          SettingsProvider(repository: repo, scheduler: scheduler);

      await provider.init();

      // مطفأ: يُحفظ الوقت دون جدولة.
      await provider.setReminderTime(hour: 9, minute: 30);
      expect(scheduler.scheduleCount, 0);
      expect(provider.reminderLabel, '09:30');

      await provider.setReminderEnabled(true);
      final afterEnable = scheduler.scheduleCount;

      await provider.setReminderTime(hour: 21, minute: 15);
      expect(scheduler.scheduleCount, afterEnable + 1);
      expect(scheduler.lastHour, 21);
      expect(scheduler.lastMinute, 15);
    });

    test('سحب الإذن من إعدادات النظام يُطفئ التنبيه عند الإقلاع', () async {
      // المستخدم فعّل التنبيه سابقاً ثم منع الإشعارات من النظام.
      final repo = _FakeSettingsRepository(
        const AppSettings(reminderEnabled: true, reminderHour: 19),
      );
      final scheduler = _FakeScheduler(alreadyHasPermission: false);
      final provider =
          SettingsProvider(repository: repo, scheduler: scheduler);

      await provider.init();

      expect(provider.reminderEnabled, isFalse);
      expect(scheduler.scheduleCount, 0);
      expect(repo.settings.reminderEnabled, isFalse);
    });

    test('الإذن الممنوح مسبقاً لا يُطلب مجدداً', () async {
      final repo = _FakeSettingsRepository();
      final scheduler = _FakeScheduler(alreadyHasPermission: true);
      final provider =
          SettingsProvider(repository: repo, scheduler: scheduler);

      await provider.init();
      await provider.setReminderEnabled(true);

      expect(scheduler.permissionRequests, 0);
      expect(scheduler.scheduleCount, 1);
    });
  });

  group('حساب موعد التنبيه القادم', () {
    setUpAll(tz_data.initializeTimeZones);

    test('الموعد اليوم إن لم يمضِ بعد', () {
      final location = tz.getLocation('Asia/Riyadh');
      final now = tz.TZDateTime(location, 2026, 8, 4, 14, 0);

      final next = LocalNotificationScheduler.nextInstanceOf(20, 0, now);

      expect(next.day, 4);
      expect(next.hour, 20);
    });

    test('الموعد غداً إن مضى وقته اليوم', () {
      final location = tz.getLocation('Asia/Riyadh');
      final now = tz.TZDateTime(location, 2026, 8, 4, 22, 0);

      final next = LocalNotificationScheduler.nextInstanceOf(20, 0, now);

      expect(next.day, 5);
      expect(next.hour, 20);
    });

    test('الموعد غداً إن كانت اللحظة نفسها بالضبط', () {
      final location = tz.getLocation('Asia/Riyadh');
      final now = tz.TZDateTime(location, 2026, 8, 4, 20, 0);

      final next = LocalNotificationScheduler.nextInstanceOf(20, 0, now);

      expect(next.day, 5);
    });
  });
}
