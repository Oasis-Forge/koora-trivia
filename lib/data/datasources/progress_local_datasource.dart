import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_config.dart';
import '../models/progress_model.dart';

abstract class ProgressLocalDataSource {
  Future<Map<String, CategoryProgressModel>> read();
  Future<void> write(CategoryProgressModel progress);
  Future<void> clear();
}

/// تخزين تقدّم المستويات محلياً.
///
/// الشكل المحفوظ:
/// ```json
/// { "version": 1, "categories": { "world_cup": [3,3,2,0,0,0,0,0,0,0] } }
/// ```
/// المفتاح هو `slug` لا الاسم العربي — الأسماء قد تتغيّر، الـ slug ثابت.
class PrefsProgressDataSource implements ProgressLocalDataSource {
  static const String _key = 'level_progress_v1';

  @override
  Future<Map<String, CategoryProgressModel>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final categories = decoded['categories'] as Map<String, dynamic>? ?? {};

      return {
        for (final entry in categories.entries)
          entry.key: CategoryProgressModel.fromJson(
            entry.key,
            entry.value as List<dynamic>,
            AppConfig.levelsPerCategory,
          ),
      };
    } on FormatException {
      // بيانات تالفة — نبدأ من جديد بدل إسقاط التطبيق.
      await prefs.remove(_key);
      return {};
    }
  }

  @override
  Future<void> write(CategoryProgressModel progress) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await read();
    current[progress.slug] = progress;

    await prefs.setString(
      _key,
      json.encode({
        'version': 1,
        'categories': {
          for (final entry in current.entries) entry.key: entry.value.toJson(),
        },
      }),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
