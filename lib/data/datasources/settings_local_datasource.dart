import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> read();
  Future<void> write(AppSettings settings);
}

class PrefsSettingsDataSource implements SettingsLocalDataSource {
  static const String key = 'app_settings_v1';

  /// يحوّل النص المحفوظ إلى إعدادات، ويرمي [FormatException] لأي بنية غير
  /// متوقعة (انظر `PrefsStatsDataSource.decode`).
  static AppSettings decode(String raw) {
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return AppSettings(
        reminderEnabled: map['reminderEnabled'] as bool? ?? false,
        reminderHour: (map['reminderHour'] as int? ?? 20).clamp(0, 23),
        reminderMinute: (map['reminderMinute'] as int? ?? 0).clamp(0, 59),
        soundEnabled: map['soundEnabled'] as bool? ?? true,
        hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
        onboardingSeen: map['onboardingSeen'] as bool? ?? false,
      );
    } on TypeError catch (e) {
      throw FormatException('بنية إعدادات غير متوقعة: $e');
    }
  }

  @override
  Future<AppSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const AppSettings();

    try {
      return decode(raw);
    } on FormatException {
      await prefs.remove(key);
      return const AppSettings();
    }
  }

  @override
  Future<void> write(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      json.encode({
        'reminderEnabled': settings.reminderEnabled,
        'reminderHour': settings.reminderHour,
        'reminderMinute': settings.reminderMinute,
        'soundEnabled': settings.soundEnabled,
        'hapticsEnabled': settings.hapticsEnabled,
        'onboardingSeen': settings.onboardingSeen,
      }),
    );
  }
}
