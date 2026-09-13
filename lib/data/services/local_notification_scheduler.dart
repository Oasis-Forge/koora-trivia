import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_strings.dart';
import '../../domain/repositories/reminder_scheduler.dart';

/// تنفيذ الجدولة عبر `flutter_local_notifications`.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _dailyNotificationId = 1001;
  static const String _channelId = 'daily_challenge';

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    // قاعدة بيانات المناطق الزمنية مطلوبة لأن الجدولة تتم بالتوقيت المحلي.
    tz_data.initializeTimeZones();

    // بدون هذه الخطوة تبقى `tz.local` مضبوطة على UTC، فيُطلق تنبيه الساعة
    // الثامنة مساءً في توقيت غير توقيت المستخدم.
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      // منطقة غير معروفة في قاعدة البيانات — نُبقي UTC بدل إسقاط التطبيق.
      debugPrint('تعذّر ضبط المنطقة الزمنية المحلية: $e');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> hasPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    return await android.areNotificationsEnabled() ?? false;
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    await init();
    await cancelDaily();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        AppStrings.reminderChannelName,
        channelDescription: AppStrings.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      AppStrings.reminderTitle,
      AppStrings.reminderBody,
      _nextInstanceOf(hour, minute),
      details,
      // غير مضبوط بدقة عمداً: الجدولة الدقيقة تتطلب إذن SCHEDULE_EXACT_ALARM
      // على أندرويد 12+، وهو إذن ثقيل لا يستحقه تذكير يومي.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // التكرار يومياً عند نفس الساعة.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDaily() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  /// أقرب موعد قادم للساعة المطلوبة — اليوم إن لم يمضِ، وإلا غداً.
  ///
  /// نبني الموعد في منطقة [from] نفسها لا في `tz.local`، وإلا اختلطت المناطق
  /// وأصبحت المقارنة بين لحظتين من نطاقين مختلفين.
  @visibleForTesting
  static tz.TZDateTime nextInstanceOf(
    int hour,
    int minute, [
    tz.TZDateTime? from,
  ]) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) =>
      nextInstanceOf(hour, minute);
}
