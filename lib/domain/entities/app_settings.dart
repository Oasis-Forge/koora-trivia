/// إعدادات المستخدم المحفوظة محلياً.
class AppSettings {
  const AppSettings({
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.onboardingSeen = false,
  });

  final bool reminderEnabled;

  /// ساعة التنبيه بتوقيت الجهاز المحلي (0-23).
  final int reminderHour;
  final int reminderMinute;

  final bool soundEnabled;
  final bool hapticsEnabled;

  /// هل شاهد المستخدم شاشة الترحيب؟
  final bool onboardingSeen;

  /// صيغة عرض 24 ساعة، مثل `20:00`.
  String get reminderLabel =>
      '${reminderHour.toString().padLeft(2, '0')}:'
      '${reminderMinute.toString().padLeft(2, '0')}';

  AppSettings copyWith({
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? onboardingSeen,
  }) {
    return AppSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }
}
