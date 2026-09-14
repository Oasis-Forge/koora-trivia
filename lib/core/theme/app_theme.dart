import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  /// أيقونة الزر بعد نصه: في العربية (من اليمين) تقع على يسار النص — طلب
  /// صاحب التطبيق. لا تُلغَ لزر بعينه.
  static const _iconAfterLabel = IconAlignment.end;

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.pitchDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pitchLight,
        secondary: AppColors.gold,
        surface: AppColors.cardSurface,
        error: AppColors.wrong,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.chalk,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.chalk,
        displayColor: AppColors.chalk,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.pitchDark,
          minimumSize: const Size.fromHeight(56),
          iconAlignment: _iconAfterLabel,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.chalk,
          minimumSize: const Size.fromHeight(56),
          iconAlignment: _iconAfterLabel,
          side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(iconAlignment: _iconAfterLabel),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardSurface,
        contentTextStyle: TextStyle(color: AppColors.chalk),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.cardBorder),
    );
  }
}
