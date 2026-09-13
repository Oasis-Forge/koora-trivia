import 'package:flutter/foundation.dart';

import '../../domain/repositories/ad_service.dart';

/// يغلّف [AdService] ويُخطر الواجهة عند تغيّر جاهزية الإعلان.
class AdsProvider extends ChangeNotifier {
  AdsProvider({required AdService service}) : _service = service {
    // الخدمة تُخطرنا حين يكتمل تحميل إعلان أو تتغيّر الموافقة. بدون هذا بقي
    // زر الإعلان معطّلاً بعد اكتمال التحميل حتى يُعاد بناؤه لسبب آخر.
    _service.onChanged = notifyListeners;
  }

  final AdService _service;

  bool _initialized = false;
  bool _showing = false;

  bool get isReady => _service.isRewardedReady;
  bool get isShowing => _showing;
  bool get isInitialized => _initialized;

  /// هل تعرض الإعدادات مدخل خيارات خصوصية الإعلانات؟
  bool get isPrivacyOptionsRequired => _service.isPrivacyOptionsRequired;

  Future<void> init() async {
    await _service.init();
    _initialized = true;
    notifyListeners();
  }

  /// عرض إعلان مكافأ. يعيد النتيجة ليقرر المستدعي هل يمنح المكافأة.
  ///
  /// **لا تمنح المكافأة إلا عند [RewardResult.earned]** — الإغلاق المبكر
  /// لا يستحق شيئاً، وإلا تعلّم اللاعب فتح الإعلان وإغلاقه فوراً.
  Future<RewardResult> showRewarded() async {
    if (_showing) return RewardResult.unavailable;

    _showing = true;
    notifyListeners();

    try {
      return await _service.showRewarded();
    } finally {
      _showing = false;
      notifyListeners();
    }
  }

  /// يعيد `false` إن تعذّر عرض النموذج لتعرض الشاشة رسالة.
  Future<bool> showPrivacyOptions() => _service.showPrivacyOptions();

  void onAppResumed() => _service.onAppResumed();

  void recordRoundFinished() => _service.recordRoundFinished();

  Future<bool> maybeShowInterstitial() => _service.maybeShowInterstitial();

  set adsRemoved(bool value) => _service.adsRemoved = value;

  @override
  void dispose() {
    // الخدمة تعيش أطول من المزوّد؛ إخطار مزوّد مُتلَف يرمي خطأ.
    _service.onChanged = null;
    super.dispose();
  }
}
