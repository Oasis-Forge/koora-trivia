import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_stats_model.dart';

abstract class StatsLocalDataSource {
  Future<UserStatsModel> read();
  Future<void> write(UserStatsModel stats);
}

/// تخزين محلي دائم للسلسلة والإحصائيات عبر SharedPreferences.
class PrefsStatsDataSource implements StatsLocalDataSource {
  static const String key = 'user_stats_v1';

  /// يحوّل النص المحفوظ إلى نموذج، ويرمي [FormatException] لأي بنية غير متوقعة.
  ///
  /// `as int?` على قيمة من نوع آخر يرمي TypeError لا FormatException، فكانت
  /// قيمة واحدة بنوع خاطئ (من نسخة احتياطية مثلاً) تُسقط التحميل كله.
  static UserStatsModel decode(String raw) {
    try {
      final stats = UserStatsModel.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
      // مفتاح يوم لا يُقرأ كتاريخ يُسقط حساب السلسلة عند كل عرض للرئيسية.
      for (final dayKey in [stats.lastDailyDayKey, stats.lastPlayedDayKey]) {
        if (dayKey != null && DateTime.tryParse(dayKey) == null) {
          throw FormatException('مفتاح يوم غير صالح', dayKey);
        }
      }
      return stats;
    } on TypeError catch (e) {
      throw FormatException('بنية إحصائيات غير متوقعة: $e');
    }
  }

  @override
  Future<UserStatsModel> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const UserStatsModel();

    try {
      return decode(raw);
    } on FormatException {
      // بيانات تالفة — نبدأ من جديد بدل إسقاط التطبيق.
      await prefs.remove(key);
      return const UserStatsModel();
    }
  }

  @override
  Future<void> write(UserStatsModel stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(stats.toJson()));
  }
}
