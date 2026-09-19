import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/repositories/ad_service.dart';

/// خدمة إعلانات مزيّفة مشتركة بين الاختبارات — بلا SDK ولا منصة.
class FakeAdService implements AdService {
  FakeAdService({
    this.ready = true,
    this.result = RewardResult.earned,
    this.privacyOptionsRequired = false,
    this.privacyFormShown = true,
    this.bannersAllowed = false,
  });

  bool ready;
  RewardResult result;
  bool privacyOptionsRequired;
  bool privacyFormShown;

  /// افتراضياً مطفأ: اختبارات الودجات لا تملك منصة تحمّل إعلاناً حقيقياً.
  bool bannersAllowed;

  void Function()? listener;
  bool adsRemovedValue = false;
  int showRewardedCalls = 0;
  int privacyFormCalls = 0;
  int resumeCalls = 0;
  int interstitialsShown = 0;
  int rounds = 0;

  /// يحاكي اكتمال تحميل إعلان أو ضياعه: يغيّر الجاهزية ويُخطر المستمع كما
  /// تفعل الخدمة الحقيقية.
  void setReady(bool value) {
    ready = value;
    listener?.call();
  }

  @override
  Future<void> init() async {}

  @override
  set onChanged(void Function()? value) => listener = value;

  /// ما يُستدعى قبل كل إعلان بملء الشاشة «يُعرض».
  void Function()? beforeFullScreen;

  @override
  set beforeFullScreenAd(void Function()? callback) =>
      beforeFullScreen = callback;

  @override
  bool get isRewardedReady => ready;

  @override
  bool get isPrivacyOptionsRequired => privacyOptionsRequired;

  @override
  bool get areBannersAllowed => bannersAllowed && !adsRemovedValue;

  @override
  String get bannerUnitId => 'fake-banner';

  @override
  Future<bool> showPrivacyOptions() async {
    privacyFormCalls++;
    return privacyFormShown;
  }

  @override
  void onAppResumed() => resumeCalls++;

  @override
  Future<RewardResult> showRewarded() async {
    showRewardedCalls++;
    if (ready) beforeFullScreen?.call();
    return result;
  }

  @override
  void recordRoundFinished() => rounds++;

  /// المزيّف يتجاهل مفتاح الإطلاق عمداً ليختبر منطق العدّ نفسه.
  @override
  Future<bool> maybeShowInterstitial() async {
    if (adsRemovedValue) return false;
    if (rounds < AppConfig.roundsBetweenInterstitials) return false;
    rounds = 0;
    beforeFullScreen?.call();
    interstitialsShown++;
    return true;
  }

  @override
  set adsRemoved(bool value) {
    adsRemovedValue = value;
    // الخدمة الحقيقية تُخطر هنا ليختفي الشريط فوراً.
    listener?.call();
  }
}
