import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_update_status.dart';
import '../../domain/repositories/app_updater.dart';

/// التحديث من داخل التطبيق عبر Google Play In-App Updates.
///
/// يعمل فقط لتطبيق مثبّت من Play. خارج ذلك (المحاكي، APK مثبّت يدوياً) يرمي Play
/// خطأً متوقعاً يُلتقط هنا فتُعامل الحالة كأن لا تحديث، ولا يُسجَّل في سجل الأخطاء.
///
/// وقت عرض التحديث المرن خاص بالجهاز، فليس ضمن النسخة الاحتياطية.
class PlayAppUpdater implements AppUpdater {
  PlayAppUpdater({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const String key = 'update_prompt_v1';

  final DateTime Function() _clock;

  @override
  Future<AppUpdateStatus> check() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AppUpdateStatus.none;
    }
    try {
      final info = await InAppUpdate.checkForUpdate();
      return AppUpdateStatus(
        available:
            info.updateAvailability == UpdateAvailability.updateAvailable,
        inProgress: info.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress,
        downloaded: info.installStatus == InstallStatus.downloaded,
        immediateAllowed: info.immediateUpdateAllowed,
        flexibleAllowed: info.flexibleUpdateAllowed,
        priority: info.updatePriority,
      );
    } catch (e) {
      debugPrint('تعذّر سؤال Play عن تحديث: $e');
      return AppUpdateStatus.none;
    }
  }

  @override
  Future<void> updateImmediately() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('تعذّر التحديث الإلزامي: $e');
    }
  }

  @override
  Future<bool> startFlexibleUpdate() async {
    try {
      // يكتمل بعد انتهاء التنزيل، لا بعد موافقة اللاعب فقط.
      return await InAppUpdate.startFlexibleUpdate() ==
          AppUpdateResult.success;
    } catch (e) {
      debugPrint('تعذّر تنزيل التحديث: $e');
      return false;
    }
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('تعذّر تثبيت التحديث: $e');
    }
  }

  @override
  Future<DateTime?> lastFlexibleAskAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> recordFlexibleAsk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _clock().toIso8601String());
  }
}
