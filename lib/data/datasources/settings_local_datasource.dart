import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> read();
  Future<void> write(AppSettings settings);
}

class PrefsSettingsDataSource implements SettingsLocalDataSource {
  static const String _key = 'app_settings_v1';

  @override
  Future<AppSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const AppSettings();

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
    } on FormatException {
      await prefs.remove(_key);
      return const AppSettings();
    }
  }

  @override
  Future<void> write(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
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
