import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_stats_model.dart';

abstract class StatsLocalDataSource {
  Future<UserStatsModel> read();
  Future<void> write(UserStatsModel stats);
}

/// تخزين محلي دائم للسلسلة والإحصائيات عبر SharedPreferences.
class PrefsStatsDataSource implements StatsLocalDataSource {
  static const String _key = 'user_stats_v1';

  @override
  Future<UserStatsModel> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const UserStatsModel();

    try {
      return UserStatsModel.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      // بيانات تالفة — نبدأ من جديد بدل إسقاط التطبيق.
      await prefs.remove(_key);
      return const UserStatsModel();
    }
  }

  @override
  Future<void> write(UserStatsModel stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(stats.toJson()));
  }
}
