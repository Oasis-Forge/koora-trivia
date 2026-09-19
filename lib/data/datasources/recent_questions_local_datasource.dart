import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/recent_questions_repository.dart';

/// ذاكرة الجولة السريعة في SharedPreferences: قائمة معرّفات JSON.
///
/// ضمن النسخة الاحتياطية (`_decoders` في `BackupRepositoryImpl`) كبقية المفاتيح.
class PrefsRecentQuestionsDataSource implements RecentQuestionsRepository {
  static const String key = 'recent_questions_v1';

  /// يرمي [FormatException] لأي بنية غير قائمة أعداد، كبقية مفاتيح النسخة.
  static List<int> decode(String raw) {
    try {
      return [for (final id in json.decode(raw) as List<dynamic>) id as int];
    } on TypeError catch (e) {
      throw FormatException('بنية أسئلة حديثة غير متوقعة: $e');
    }
  }

  @override
  Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      return decode(raw);
    } on FormatException {
      // ذاكرة تالفة لا تستحق إسقاط الجولة: تبدأ من جديد.
      return const [];
    }
  }

  @override
  Future<void> save(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(ids));
  }
}
