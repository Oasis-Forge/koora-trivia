import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/repositories/app_info.dart';

/// رقم الإصدار من `pubspec.yaml` كما بُني فعلاً، بدل نص ثابت يُنسى تحديثه.
class PackageAppInfo implements AppInfo {
  Future<String>? _version;

  @override
  Future<String> version() => _version ??= _load();

  static Future<String> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (e) {
      debugPrint('تعذّرت قراءة رقم الإصدار: $e');
      return '—';
    }
  }
}
