import '../entities/error_entry.dart';

/// سجل محلي للأخطاء غير الملتقطة. لا يغادر الجهاز إلا إن أرسله اللاعب بنفسه.
abstract class ErrorLog {
  /// لا يرمي أبداً: فشل التسجيل لا يجوز أن يولّد خطأً جديداً يُسجَّل بدوره.
  Future<void> record(Object error, StackTrace? stack);

  /// أحدث الأخطاء أولاً.
  Future<List<ErrorEntry>> recent();
}
