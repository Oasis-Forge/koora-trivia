import '../entities/app_update_status.dart';

/// تحديث التطبيق من متجر Play من داخله.
abstract class AppUpdater {
  /// حالة التحديث، أو `AppUpdateStatus.none` إن تعذّر سؤال Play.
  Future<AppUpdateStatus> check();

  /// شاشة Play الكاملة التي تمنع اللعب حتى يكتمل التحديث.
  Future<void> updateImmediately();

  /// نافذة Play تعرض تنزيل التحديث في الخلفية. يعيد `true` إن اكتمل التنزيل.
  Future<bool> startFlexibleUpdate();

  /// يثبّت التحديث المنزَّل ويعيد تشغيل التطبيق.
  Future<void> completeFlexibleUpdate();

  /// آخر مرة عُرض فيها التحديث المرن، أو `null` إن لم يُعرض.
  Future<DateTime?> lastFlexibleAskAt();

  Future<void> recordFlexibleAsk();
}
