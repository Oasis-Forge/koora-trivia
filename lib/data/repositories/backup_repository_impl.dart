import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/backup_repository.dart';

/// ينسخ مفاتيح التخزين الأربعة إلى نص Base64 والعكس.
///
/// هذا هو البديل المحلي عن الحفظ السحابي: ينسخ المستخدم النص ويلصقه في الجهاز
/// الجديد. بلا حساب وبلا خادم وبلا إنترنت.
class BackupRepositoryImpl implements BackupRepository {
  /// كل المفاتيح التي تُشكّل تقدّم المستخدم.
  static const List<String> _keys = [
    'user_stats_v1',
    'level_progress_v1',
    'economy_v1',
    'app_settings_v1',
  ];

  /// إصدار صيغة النسخة — يرتفع إن تغيّرت بنية المفاتيح.
  static const int _formatVersion = 1;

  @override
  Future<String> export() async {
    final prefs = await SharedPreferences.getInstance();

    final payload = <String, dynamic>{
      'v': _formatVersion,
      'data': {
        for (final key in _keys)
          if (prefs.getString(key) != null) key: prefs.getString(key),
      },
    };

    return base64Url.encode(utf8.encode(json.encode(payload)));
  }

  @override
  Future<bool> import(String code) async {
    final cleaned = code.trim().replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty) return false;

    try {
      final decoded =
          json.decode(utf8.decode(base64Url.decode(cleaned)))
              as Map<String, dynamic>;

      // نرفض الإصدارات الأحدث بدل كتابة بيانات لا نفهمها.
      final version = decoded['v'] as int?;
      if (version == null || version > _formatVersion) return false;

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null || data.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      for (final key in _keys) {
        final value = data[key];
        if (value is String) {
          await prefs.setString(key, value);
        }
      }
      return true;
    } catch (_) {
      // نص تالف أو ليس نسخة احتياطية أصلاً.
      return false;
    }
  }
}
