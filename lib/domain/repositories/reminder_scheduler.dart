import '../entities/reminder_plan.dart';

/// عقد مجرّد لجدولة تنبيهات التحدي اليومي.
///
/// يبقى `domain` خالياً من أي اعتماد على حزمة الإشعارات أو على Flutter.
abstract class ReminderScheduler {
  /// تهيئة النظام. تُستدعى مرة واحدة عند الإقلاع.
  Future<void> init();

  /// طلب إذن الإشعارات. يعيد `true` إن مُنح.
  Future<bool> requestPermission();

  /// هل الإذن ممنوح حالياً؟
  Future<bool> hasPermission();

  /// يستبدل كل التنبيهات المجدولة بهذه الخطة، تنبيهاً واحداً لكل يوم فيها.
  Future<void> schedule(List<ReminderPlan> plans);

  /// إلغاء كل التنبيهات المجدولة.
  Future<void> cancelAll();
}
