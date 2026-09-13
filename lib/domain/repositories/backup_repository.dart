/// تصدير واستيراد التقدّم كنص، بديلاً محلياً عن الحفظ السحابي.
abstract class BackupRepository {
  /// يعيد نص النسخة الاحتياطية جاهزاً للنسخ.
  Future<String> export();

  /// يستورد نصاً. يعيد `false` إن كان تالفاً أو من إصدار غير مدعوم.
  Future<bool> import(String code);
}
