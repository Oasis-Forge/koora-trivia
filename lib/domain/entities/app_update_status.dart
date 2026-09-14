/// ما يقوله متجر Play عن تحديث للتطبيق.
class AppUpdateStatus {
  const AppUpdateStatus({
    this.available = false,
    this.inProgress = false,
    this.downloaded = false,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.priority = 0,
  });

  /// لا تحديث، أو تعذّر سؤال Play (تثبيت من خارج المتجر مثلاً).
  static const none = AppUpdateStatus();

  /// إصدار أحدث منشور على المتجر.
  final bool available;

  /// تحديث إلزامي بدأ ولم يكتمل: عاد اللاعب إلى التطبيق قبل انتهائه.
  final bool inProgress;

  /// تحديث مرن نُزّل وينتظر إعادة التشغيل.
  final bool downloaded;

  final bool immediateAllowed;
  final bool flexibleAllowed;

  /// أولوية الإصدار من 0 إلى 5. تُضبط عبر Google Play Developer API عند النشر،
  /// لا من واجهة Play Console.
  final int priority;
}
