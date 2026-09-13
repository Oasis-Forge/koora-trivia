import 'package:flutter/foundation.dart';

import '../../domain/repositories/ad_service.dart';

/// يغلّف [AdService] ويُخطر الواجهة عند تغيّر جاهزية الإعلان.
class AdsProvider extends ChangeNotifier {
  AdsProvider({required AdService service}) : _service = service;

  final AdService _service;

  bool _initialized = false;
  bool _showing = false;

  bool get isReady => _service.isRewardedReady;
  bool get isShowing => _showing;
  bool get isInitialized => _initialized;

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

  void recordRoundFinished() => _service.recordRoundFinished();

  Future<bool> maybeShowInterstitial() => _service.maybeShowInterstitial();

  set adsRemoved(bool value) => _service.adsRemoved = value;
}
