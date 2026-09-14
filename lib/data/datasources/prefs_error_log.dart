import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_config.dart';
import '../../domain/entities/error_entry.dart';
import '../../domain/repositories/error_log.dart';

/// سجل الأخطاء في SharedPreferences: آخر [AppConfig.errorLogMaxEntries] خطأً فقط.
///
/// ليس ضمن النسخة الاحتياطية عمداً: أخطاء جهاز قديم لا تفيد في جهاز جديد.
class PrefsErrorLog implements ErrorLog {
  PrefsErrorLog({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const String key = 'error_log_v1';
  static const int _maxMessageLength = 300;
  static const int _maxStackLines = 4;

  final DateTime Function() _clock;

  /// الكتابات متسلسلة: خطآن في الإطار نفسه كانا سيقرآن القائمة نفسها فيضيع أحدهما.
  Future<void> _pending = Future.value();

  @override
  Future<void> record(Object error, StackTrace? stack) {
    final at = _clock();
    return _pending = _pending.then((_) => _write(at, error, stack));
  }

  Future<void> _write(DateTime at, Object error, StackTrace? stack) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _decode(prefs.getString(key));

      final message = '$error';
      entries.insert(0, {
        'at': at.toIso8601String(),
        'message': message.length > _maxMessageLength
            ? message.substring(0, _maxMessageLength)
            : message,
        if (stack != null)
          'stack': stack
              .toString()
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .take(_maxStackLines)
              .join('\n'),
      });

      await prefs.setString(
        key,
        json.encode(entries.take(AppConfig.errorLogMaxEntries).toList()),
      );
    } catch (_) {
      // لا نسجّل فشل السجل نفسه — كان سيولّد حلقة لا تنتهي.
    }
  }

  @override
  Future<List<ErrorEntry>> recent() async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final entry in _decode(prefs.getString(key)))
        if (DateTime.tryParse(entry['at'] as String) case final at?)
          ErrorEntry(
            at: at,
            message: entry['message'] as String,
            stack: entry['stack'] as String?,
          ),
    ];
  }

  /// قائمة مدخلات صالحة، أو قائمة فارغة إن كان المحفوظ تالفاً.
  static List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic> &&
              item['at'] is String &&
              item['message'] is String &&
              (item['stack'] == null || item['stack'] is String))
            item,
      ];
    } catch (_) {
      return [];
    }
  }
}
