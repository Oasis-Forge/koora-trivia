import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/reminder_plan.dart';
import '../../domain/repositories/reminder_scheduler.dart';

/// تنفيذ الجدولة عبر `flutter_local_notifications`.
///
/// ⚠️ يحتاج مستقبِلَي الحزمة في `AndroidManifest.xml`، وإلا جُدول التنبيه ولم
/// يُطلق أبداً — وهذا ما حدث حتى الإصدار 1.0.3.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// أيقونة شريط الحالة: شكل أبيض أحادي اللون في `res/drawable-*`. أيقونة
  /// التطبيق الملوّنة تظهر هناك شكلاً أبيض فارغاً.
  static const String statusBarIcon = 'ic_stat_notification';

  /// المعرّف الأول هو نفسه معرّف التنبيه المتكرر في الإصدار 1.0.3، فيُلغى معه.
  static const int _firstNotificationId = 1001;

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
      android: AndroidInitializationSettings(statusBarIcon),
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
  Future<void> schedule(List<ReminderPlan> plans) async {
    await init();
    await cancelAll();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        AppStrings.reminderChannelName,
        channelDescription: AppStrings.reminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: statusBarIcon,
      ),
    );

    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < plans.length && i < AppConfig.reminderDaysAhead; i++) {
      final plan = plans[i];
      final at = plan.at;
      final scheduled = tz.TZDateTime(
        tz.local,
        at.year,
        at.month,
        at.day,
        at.hour,
        at.minute,
      );
      // الحزمة ترفض موعداً مضى، وقد يمضي موعد اليوم بين التخطيط والجدولة.
      if (!scheduled.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        _firstNotificationId + i,
        AppStrings.reminderTitle,
        bodyFor(plan),
        scheduled,
        details,
        // غير مضبوط بدقة عمداً: الجدولة الدقيقة تتطلب إذن SCHEDULE_EXACT_ALARM
        // على أندرويد 12+، وهو إذن ثقيل لا يستحقه تذكير يومي.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // بلا matchDateTimeComponents عمداً: التنبيه المتكرر يُوضع عند أقرب موعد
        // للساعة متجاهلاً التاريخ، فلا يمكن تخطّي يوم أُنجز فيه التحدي.
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    // بالمعرّفات لا بـ cancelAll() حتى لا نمسّ أي إشعار آخر يُضاف لاحقاً.
    for (var i = 0; i < AppConfig.reminderDaysAhead; i++) {
      await _plugin.cancel(_firstNotificationId + i);
    }
  }

  /// نص التنبيه: يذكر السلسلة حين تكون قائمة، وعدد أسئلة التحدي من الإعدادات.
  @visibleForTesting
  static String bodyFor(ReminderPlan plan) {
    final questions = ArabicCount.format(
      AppConfig.dailyQuestionCount,
      ArabicNoun.question,
    );
    final streak = plan.streak;
    if (streak == null || streak <= 0) return AppStrings.reminderBody(questions);

    return AppStrings.reminderBodyStreak(
      ArabicCount.format(streak, ArabicNoun.day),
      questions,
    );
  }
}
