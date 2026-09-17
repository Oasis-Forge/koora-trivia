import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي لما اشتراه اللاعب مرة واحدة («إزالة الإعلانات»).
///
/// ⚠️ **ليس مفتاحاً ضمن النسخ الاحتياطي عمداً** (فلا يُضاف إلى `_decoders` في
/// `BackupRepositoryImpl`): رمز النسخة يُشارَك بين الأجهزة، فلو حمل الاستحقاق
/// لأصبح الشراء مجانياً لمن نسخ الرمز. المصدر الحقيقي هو Play، ويُقرأ عند كل
/// إقلاع؛ وهذه نسخة محلية لتعمل إزالة الإعلانات دون اتصال.
abstract class EntitlementLocalDataSource {
  Future<bool> readAdsRemoved();
  Future<void> writeAdsRemoved(bool value);
}

class PrefsEntitlementDataSource implements EntitlementLocalDataSource {
  static const String key = 'entitlements_v1_ads_removed';

  @override
  Future<bool> readAdsRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  @override
  Future<void> writeAdsRemoved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
