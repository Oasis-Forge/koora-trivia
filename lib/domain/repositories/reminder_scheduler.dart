/// عقد مجرّد لجدولة تنبيه التحدي اليومي.
///
/// يبقى `domain` خالياً من أي اعتماد على حزمة الإشعارات أو على Flutter.
abstract class ReminderScheduler {
  /// تهيئة النظام. تُستدعى مرة واحدة عند الإقلاع.
  Future<void> init();

  /// طلب إذن الإشعارات. يعيد `true` إن مُنح.
  Future<bool> requestPermission();

  /// هل الإذن ممنوح حالياً؟
  Future<bool> hasPermission();

  /// جدولة تنبيه يومي متكرر عند الساعة والدقيقة المحددتين.
  Future<void> scheduleDaily({required int hour, required int minute});

  /// إلغاء التنبيه اليومي.
  Future<void> cancelDaily();
}
