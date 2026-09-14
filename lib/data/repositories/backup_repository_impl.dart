import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/backup_repository.dart';
import '../datasources/economy_local_datasource.dart';
import '../datasources/progress_local_datasource.dart';
import '../datasources/settings_local_datasource.dart';
import '../datasources/stats_local_datasource.dart';

/// ينسخ مفاتيح التخزين الأربعة إلى نص Base64 والعكس.
///
/// هذا هو البديل المحلي عن الحفظ السحابي: ينسخ المستخدم النص ويلصقه في الجهاز
/// الجديد. بلا حساب وبلا خادم وبلا إنترنت.
class BackupRepositoryImpl implements BackupRepository {
  /// كل المفاتيح التي تُشكّل تقدّم المستخدم، ومع كل مفتاح المحلّل الذي يقرؤه
  /// به التطبيق — فالقيمة المستوردة تُفحص بنفس القواعد قبل كتابتها.
  static const Map<String, Object Function(String raw)> _decoders = {
    PrefsStatsDataSource.key: PrefsStatsDataSource.decode,
    PrefsProgressDataSource.key: PrefsProgressDataSource.decode,
    PrefsEconomyDataSource.key: PrefsEconomyDataSource.decode,
    PrefsSettingsDataSource.key: PrefsSettingsDataSource.decode,
  };

  /// إصدار صيغة النسخة — يرتفع إن تغيّرت بنية المفاتيح.
  static const int _formatVersion = 1;

  @override
  Future<String> export() async {
    final prefs = await SharedPreferences.getInstance();

    final payload = <String, dynamic>{
      'v': _formatVersion,
      'data': {
        for (final key in _decoders.keys)
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
      if (data == null) return false;

      // نفحص كل القيم قبل كتابة أي منها: نسخة نصفها تالف لا تُكتب نصفَ كتابة،
      // وقيمة بنوع خاطئ لا تصل إلى التخزين لتُسقط التطبيق عند قراءتها.
      final values = <String, String>{};
      for (final MapEntry(:key, value: decode) in _decoders.entries) {
        final value = data[key];
        if (value == null) continue;
        if (value is! String) return false;
        decode(value);
        values[key] = value;
      }
      if (values.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      for (final MapEntry(:key, :value) in values.entries) {
        await prefs.setString(key, value);
      }
      return true;
    } catch (_) {
      // نص تالف أو ليس نسخة احتياطية أصلاً.
      return false;
    }
  }
}
