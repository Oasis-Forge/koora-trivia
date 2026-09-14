/// معلومات عن نسخة التطبيق المثبّتة.
abstract class AppInfo {
  /// رقم الإصدار ورقم البناء، مثل `1.0.4 (5)`.
  Future<String> version();
}
