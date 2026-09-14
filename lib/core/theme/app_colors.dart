import 'package:flutter/material.dart';

/// ألوان مظهر واحد. المظاهر كلها داكنة بتصميم الملعب نفسه: تتغيّر الأرضية
/// والبطاقات، ويبقى الذهب والطباشير وألوان الصحيح والخطأ بمعانيها.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.pitchDark,
    required this.pitchDeep,
    required this.pitchMid,
    required this.pitchLight,
    required this.cardSurface,
    this.pitchStripe = const Color(0x14FFFFFF),
    this.gold = const Color(0xFFF5C542),
    this.goldDeep = const Color(0xFFCF9A17),
    this.chalk = const Color(0xFFF3F7F4),
    this.chalkMuted = const Color(0xB3F3F7F4),
    this.correct = const Color(0xFF2ECC71),
    this.wrong = const Color(0xFFE74C3C),
    this.cardBorder = const Color(0x33FFFFFF),
  });

  /// مفتاح ثابت يُحفظ في الإعدادات — لا يُغيَّر بعد النشر.
  final String id;

  final Color pitchDark;
  final Color pitchDeep;
  final Color pitchMid;
  final Color pitchLight;
  final Color pitchStripe;
  final Color gold;
  final Color goldDeep;
  final Color chalk;
  final Color chalkMuted;
  final Color correct;
  final Color wrong;
  final Color cardSurface;
  final Color cardBorder;

  /// «ملعب أخضر» — التصميم الأصلي والافتراضي.
  static const green = AppPalette(
    id: 'green',
    pitchDark: Color(0xFF06301C),
    pitchDeep: Color(0xFF0A4429),
    pitchMid: Color(0xFF11623A),
    pitchLight: Color(0xFF1B8A50),
    cardSurface: Color(0xFF0E4E30),
  );

  /// «ليلي أزرق».
  static const blue = AppPalette(
    id: 'blue',
    pitchDark: Color(0xFF071A30),
    pitchDeep: Color(0xFF0B2A4A),
    pitchMid: Color(0xFF123D66),
    pitchLight: Color(0xFF1E5E9A),
    cardSurface: Color(0xFF0F3558),
  );

  /// «بنفسجي».
  static const purple = AppPalette(
    id: 'purple',
    pitchDark: Color(0xFF190B2E),
    pitchDeep: Color(0xFF271249),
    pitchMid: Color(0xFF391B66),
    pitchLight: Color(0xFF5A2E99),
    cardSurface: Color(0xFF2E1654),
  );

  /// «كلاسيكو أحمر». لون الخطأ أفتح هنا حتى لا يذوب في الأرضية الحمراء.
  static const red = AppPalette(
    id: 'red',
    pitchDark: Color(0xFF2A0810),
    pitchDeep: Color(0xFF3F0D1A),
    pitchMid: Color(0xFF5C1527),
    pitchLight: Color(0xFF8A2139),
    cardSurface: Color(0xFF4A1020),
    wrong: Color(0xFFFF7B6B),
  );

  static const List<AppPalette> all = [green, blue, purple, red];

  /// مظهر غير معروف (نسخة احتياطية أحدث مثلاً) يعود إلى الأخضر.
  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => green);
}

/// الألوان الحالية، تُقرأ وقت البناء. تغيير المظهر يعيد بناء الشجرة كلها
/// (انظر `PaletteScope`)، فلا تُحفظ هذه القيم في ثوابت.
class AppColors {
  const AppColors._();

  static AppPalette _current = AppPalette.green;

  static AppPalette get current => _current;

  static void use(AppPalette palette) => _current = palette;

  static Color get pitchDark => _current.pitchDark;
  static Color get pitchDeep => _current.pitchDeep;
  static Color get pitchMid => _current.pitchMid;
  static Color get pitchLight => _current.pitchLight;
  static Color get pitchStripe => _current.pitchStripe;

  static Color get gold => _current.gold;
  static Color get goldDeep => _current.goldDeep;

  static Color get chalk => _current.chalk;
  static Color get chalkMuted => _current.chalkMuted;

  static Color get correct => _current.correct;
  static Color get wrong => _current.wrong;
  static Color get cardSurface => _current.cardSurface;
  static Color get cardBorder => _current.cardBorder;

  static LinearGradient get pitchGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [pitchDeep, pitchDark],
      );

  static LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [gold, goldDeep],
      );
}
