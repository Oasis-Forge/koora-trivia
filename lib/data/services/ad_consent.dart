import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// موافقة الخصوصية خلف واجهة صغيرة، حتى تُختبر بوابة الإعلانات دون SDK.
abstract class AdConsent {
  /// يحدّث حالة الموافقة ويعرض النموذج إن لزم، ويكتمل بعد إغلاقه.
  ///
  /// لا يرمي. يعيد `false` إن فشل التحديث أو تعذّر عرض النموذج (انقطاع الاتصال
  /// مثلاً) — أي أن المحاولة تستحق الإعادة لاحقاً — وتبقى الحالة السابقة قائمة.
  Future<bool> gather();

  /// هل تسمح الموافقة الحالية بطلب الإعلانات؟
  Future<bool> canRequestAds();

  /// هل يجب عرض مدخل خيارات الخصوصية في الإعدادات؟
  Future<bool> isPrivacyOptionsRequired();

  /// يعرض نموذج خيارات الخصوصية. يعيد `false` إن تعذّر عرضه.
  Future<bool> showPrivacyOptionsForm();
}

/// التنفيذ الحقيقي عبر منصة غوغل لإدارة الموافقة (UMP).
class UmpAdConsent implements AdConsent {
  /// [debugEea] يحاكي مستخدماً أوروبياً لاختبار النموذج على المحاكي، ولا يُمرَّر
  /// إلا في بناء التطوير (انظر `Injector`).
  UmpAdConsent({this.debugEea = false});

  final bool debugEea;

  @override
  Future<bool> gather() async {
    try {
      final updated = Completer<bool>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(
          consentDebugSettings: debugEea
              ? ConsentDebugSettings(
                  debugGeography: DebugGeography.debugGeographyEea,
                )
              : null,
        ),
        () => updated.complete(true),
        (error) {
          debugPrint('تعذّر تحديث حالة الموافقة: ${error.message}');
          updated.complete(false);
        },
      );
      if (!await updated.future) return false;

      // النموذج نفسه يقرر هل الموافقة مطلوبة أصلاً (المستخدمون في أوروبا مثلاً)،
      // والاستدعاء لا يكتمل إلا بعد إغلاقه — وهذا ما ننتظره قبل أي إعلان.
      var formOk = true;
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint('تعذّر عرض نموذج الموافقة: ${error.message}');
          formOk = false;
        }
      });
      return formOk;
    } catch (e) {
      debugPrint('خطأ في طلب الموافقة: $e');
      return false;
    }
  }

  @override
  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      // عند الشك لا نطلب إعلاناً — خسارة إعلان أهون من مخالفة سياسة الموافقة.
      debugPrint('تعذّرت قراءة حالة الموافقة: $e');
      return false;
    }
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('تعذّرت قراءة حالة خيارات الخصوصية: $e');
      return false;
    }
  }

  @override
  Future<bool> showPrivacyOptionsForm() async {
    var shown = true;
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint('تعذّر عرض خيارات الخصوصية: ${error.message}');
          shown = false;
        }
      });
    } catch (e) {
      debugPrint('خطأ في عرض خيارات الخصوصية: $e');
      return false;
    }
    return shown;
  }
}
