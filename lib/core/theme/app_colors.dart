import 'package:flutter/material.dart';

/// لوحة ألوان مستوحاة من ملعب كرة القدم: عشب أخضر، خطوط بيضاء، وذهب الكؤوس.
class AppColors {
  const AppColors._();

  static const Color pitchDark = Color(0xFF06301C);
  static const Color pitchDeep = Color(0xFF0A4429);
  static const Color pitchMid = Color(0xFF11623A);
  static const Color pitchLight = Color(0xFF1B8A50);
  static const Color pitchStripe = Color(0x14FFFFFF);

  static const Color gold = Color(0xFFF5C542);
  static const Color goldDeep = Color(0xFFCF9A17);

  static const Color chalk = Color(0xFFF3F7F4);
  static const Color chalkMuted = Color(0xB3F3F7F4);

  static const Color correct = Color(0xFF2ECC71);
  static const Color wrong = Color(0xFFE74C3C);
  static const Color cardSurface = Color(0xFF0E4E30);
  static const Color cardBorder = Color(0x33FFFFFF);

  static const LinearGradient pitchGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pitchDeep, pitchDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [gold, goldDeep],
  );
}
