/// إعدادات المستخدم المحفوظة محلياً.
class AppSettings {
  const AppSettings({
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.onboardingSeen = false,
    this.themeId = defaultThemeId,
    this.languageCode = defaultLanguageCode,
  });

  /// المظهر الأصلي «ملعب أخضر» (`AppPalette.green`).
  static const String defaultThemeId = 'green';

  /// لغة اللاعب الجديد. ما دامت العربية اللغة الوحيدة تُحفظ العربية صراحةً، حتى
  /// لا تنقلب لغة من بدأ بالعربية وهاتفه بالإنجليزية يوم تُضاف لغة ثانية. مع
  /// اللغة الثانية تصبح `String?` بقيمة `null` (لغة الهاتف) — `language_choice_test`
  /// يفرض ذلك.
  static const String defaultLanguageCode = 'ar';

  /// لغة من حُفظت إعداداته قبل خيار اللغة: كان يلعب بالعربية فيبقى عليها.
  static const String languageBeforeChoice = 'ar';

  static const Object _keep = Object();

  final bool reminderEnabled;

  /// ساعة التنبيه بتوقيت الجهاز المحلي (0-23).
  final int reminderHour;
  final int reminderMinute;

  final bool soundEnabled;
  final bool hapticsEnabled;

  /// هل شاهد المستخدم شاشة الترحيب؟
  final bool onboardingSeen;

  /// مظهر الألوان الذي اختاره المستخدم.
  final String themeId;

  /// رمز اللغة التي اختارها اللاعب (`ar`)، أو `null` لاتباع لغة الهاتف.
  final String? languageCode;


  AppSettings copyWith({
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? onboardingSeen,
    String? themeId,
    // `null` هنا قيمة حقيقية (لغة الهاتف)، فالغياب يُعرف بقيمة حارسة لا بـ`??`.
    Object? languageCode = _keep,
  }) {
    return AppSettings(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      themeId: themeId ?? this.themeId,
      languageCode: identical(languageCode, _keep)
          ? this.languageCode
          : languageCode as String?,
    );
  }
}
