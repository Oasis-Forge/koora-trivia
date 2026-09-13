import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/app_config.dart';
import '../../domain/repositories/ad_service.dart';
import 'ad_consent.dart';
import 'retrying_ad_loader.dart';

/// تنفيذ الإعلانات عبر AdMob.
///
/// معرّفات الإنتاج مضبوطة (حساب Oasis Forge · تطبيق Koora Trivia). الاختيار بين
/// الاختبار والإنتاج يتم في `Injector` عبر `useTestIds: !kReleaseMode`: بناء
/// التطوير يستخدم معرّفات غوغل التجريبية، وبناء الإصدار يستخدم معرّفاتك الحقيقية.
///
/// ⚠️ **لا تنقر على إعلان حقيقي بمعرّفك — يُعرّض الحساب للإيقاف.** لهذا يبقى
/// بناء التطوير على معرّفات الاختبار دائماً.
///
/// **الموافقة أولاً:** لا تُهيَّأ الحزمة ولا يُطلب أي إعلان قبل أن تسمح موافقة
/// UMP بذلك (`canRequestAds`). سابقاً كانت الإعلانات تُحمَّل بالتوازي مع نموذج
/// الموافقة، أي قبل أن يختار المستخدم الأوروبي شيئاً.
class AdMobAdService implements AdService {
  /// [consent] و[supportedPlatform] و[initializeSdk] و[loadRewarded]
  /// و[loadInterstitial] منافذ للاختبارات فقط؛ غيابها يعني التنفيذ الحقيقي.
  AdMobAdService({
    this.useTestIds = true,
    AdConsent? consent,
    bool? supportedPlatform,
    Future<void> Function()? initializeSdk,
    AdLoadRequest<RewardedAd>? loadRewarded,
    AdLoadRequest<InterstitialAd>? loadInterstitial,
  })  : _consent = consent ?? UmpAdConsent(),
        // الإعلانات على أندرويد فقط في هذا الإصدار.
        _supported = supportedPlatform ?? Platform.isAndroid,
        _initializeSdk = initializeSdk ?? _initializeMobileAds,
        _loadRewardedOverride = loadRewarded,
        _loadInterstitialOverride = loadInterstitial;

  final bool useTestIds;
  final AdConsent _consent;
  final bool _supported;
  final Future<void> Function() _initializeSdk;
  final AdLoadRequest<RewardedAd>? _loadRewardedOverride;
  final AdLoadRequest<InterstitialAd>? _loadInterstitialOverride;

  // معرّفات الاختبار الرسمية من وثائق غوغل.
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';

  // معرّفات الإنتاج من حساب AdMob (Oasis Forge · تطبيق Koora Trivia).
  static const String _prodRewarded = 'ca-app-pub-8287765177319119/2743596250';
  static const String _prodInterstitial =
      'ca-app-pub-8287765177319119/2959218674';

  String get _rewardedUnitId {
    if (useTestIds || _prodRewarded.isEmpty) return _testRewarded;
    return _prodRewarded;
  }

  String get _interstitialUnitId {
    if (useTestIds || _prodInterstitial.isEmpty) return _testInterstitial;
    return _prodInterstitial;
  }

  static final List<Duration> _retryDelays = [
    for (final seconds in AppConfig.adRetryDelaysSeconds)
      Duration(seconds: seconds),
  ];

  late final RetryingAdLoader<RewardedAd> _rewarded = RetryingAdLoader(
    request: _loadRewardedOverride ?? _requestRewarded,
    retryDelays: _retryDelays,
    onChanged: _notify,
    disposeAd: (ad) => ad.dispose(),
  );

  late final RetryingAdLoader<InterstitialAd> _interstitial = RetryingAdLoader(
    request: _loadInterstitialOverride ?? _requestInterstitial,
    retryDelays: _retryDelays,
    disposeAd: (ad) => ad.dispose(),
  );

  void Function()? _onChanged;
  Future<void>? _initFuture;
  Future<void>? _gatherFuture;
  bool _lastGatherFailed = false;
  Future<void>? _sdkInit;
  bool _sdkReady = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _adsRemoved = false;
  int _roundsSinceInterstitial = 0;
  DateTime? _lastInterstitialAt;

  static Future<void> _initializeMobileAds() async {
    await MobileAds.instance.initialize();
  }

  @override
  set onChanged(void Function()? listener) => _onChanged = listener;

  void _notify() => _onChanged?.call();

  @override
  set adsRemoved(bool value) {
    _adsRemoved = value;
    if (value) _interstitial.stop();
  }

  @override
  bool get isRewardedReady => _rewarded.isReady;

  @override
  bool get isPrivacyOptionsRequired => _privacyOptionsRequired;

  bool get _interstitialsWanted =>
      AppConfig.interstitialsEnabled && !_adsRemoved;

  /// هل يُسمح بطلب إعلان الآن؟ موافقة قائمة وحزمة مهيّأة.
  bool get _canLoad => _canRequestAds && _sdkReady;

  @override
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    if (!_supported) return;

    try {
      // موافقة جلسة سابقة تكفي لبدء التحميل فوراً دون انتظار تحديث حالتها عبر
      // الشبكة — النمط الذي توصي به غوغل. للمستخدم الجديد تعيد false فننتظر.
      await _applyConsentState();
    } catch (e) {
      // لا نُسقط الإقلاع بسبب الإعلانات — تطبيق بلا إعلانات أفضل من تطبيق معطّل.
      debugPrint('خطأ في تهيئة الإعلانات: $e');
    }
    await _gatherConsent();
  }

  /// يحدّث الموافقة (ويعرض النموذج إن لزم) ثم يطبّقها.
  ///
  /// طلب واحد في كل مرة: عرض النموذج نفسه قد يُطلق حدث عودة إلى التطبيق.
  Future<void> _gatherConsent() =>
      _gatherFuture ??= _runGather().whenComplete(() => _gatherFuture = null);

  Future<void> _runGather() async {
    try {
      _lastGatherFailed = !await _consent.gather();
      await _applyConsentState();
    } catch (e) {
      debugPrint('خطأ في تحديث الموافقة: $e');
    }
  }

  /// يقرأ حالة الموافقة ثم يبدأ الإعلانات أو يوقفها بحسبها.
  Future<void> _applyConsentState() async {
    final canRequest = await _consent.canRequestAds();
    final optionsRequired = await _consent.isPrivacyOptionsRequired();

    final changed = canRequest != _canRequestAds ||
        optionsRequired != _privacyOptionsRequired;
    _canRequestAds = canRequest;
    _privacyOptionsRequired = optionsRequired;
    if (changed) _notify();

    if (canRequest) {
      await _startAds();
    } else {
      _rewarded.stop();
      _interstitial.stop();
    }
  }

  Future<void> _startAds() async {
    await (_sdkInit ??= _initializeSdk());
    _sdkReady = true;

    // قد تتغيّر الموافقة أثناء انتظار التهيئة.
    if (!_canRequestAds) return;
    _rewarded.load();
    if (_interstitialsWanted) _interstitial.load();
  }

  @override
  Future<bool> showPrivacyOptions() async {
    if (!_supported) return false;

    final shown = await _consent.showPrivacyOptionsForm();
    try {
      // قد يغيّر اللاعب اختياره — نطبّق الحالة الجديدة الآن لا عند الإقلاع التالي.
      await _applyConsentState();
    } catch (e) {
      debugPrint('خطأ في تطبيق خيارات الخصوصية: $e');
    }
    return shown;
  }

  @override
  void onAppResumed() => _retryNow();

  /// محاولة فورية لما فشل سابقاً، دون انتظار أي مهلة.
  void _retryNow() {
    if (!_supported || _initFuture == null) return;

    if (!_canRequestAds) {
      // تحديث موافقة فشل (انقطاع الاتصال عند أول تشغيل مثلاً) يُعاد الآن، وإلا
      // بقيت الإعلانات ممنوعة حتى إعادة تشغيل التطبيق. أما تحديث نجح وبقيت
      // الإعلانات ممنوعة بعده فلا نعيده، حتى لا يلاحق النموذجُ اللاعبَ عند كل عودة.
      if (_lastGatherFailed) _gatherConsent();
      return;
    }
    if (!_sdkReady) return;

    _rewarded.retryNow();
    if (_interstitialsWanted) _interstitial.retryNow();
  }

  void _requestRewarded(
    void Function(RewardedAd ad) onLoaded,
    void Function(String message) onFailed,
  ) {
    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onLoaded,
        // الفشل شائع عند انقطاع الاتصال — المُحمِّل يعيد المحاولة بمهلة متصاعدة.
        onAdFailedToLoad: (error) {
          debugPrint('تعذّر تحميل الإعلان المكافأ: ${error.message}');
          onFailed(error.message);
        },
      ),
    );
  }

  void _requestInterstitial(
    void Function(InterstitialAd ad) onLoaded,
    void Function(String message) onFailed,
  ) {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (error) {
          debugPrint('تعذّر تحميل الإعلان البيني: ${error.message}');
          onFailed(error.message);
        },
      ),
    );
  }

  @override
  Future<RewardResult> showRewarded() async {
    final ad = _rewarded.take();
    if (ad == null) {
      // نحاول التحميل للمرة القادمة قبل أن نعتذر.
      _retryNow();
      return RewardResult.unavailable;
    }

    var earned = false;
    // `ad.show` يكتمل عند *عرض* الإعلان لا عند إغلاقه، بينما مكافأة المستخدم
    // تصل عبر ردّ نداء لاحق. لذا ننتظر الإغلاق عبر Completer ثم نقرر النتيجة —
    // وإلا لعاد الاستدعاء دائماً بـ dismissed ولما مُنحت المكافأة أبداً.
    final completer = Completer<RewardResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (_canLoad) _rewarded.load();
        if (!completer.isCompleted) {
          completer.complete(
            earned ? RewardResult.earned : RewardResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (_canLoad) _rewarded.load();
        if (!completer.isCompleted) {
          completer.complete(RewardResult.unavailable);
        }
      },
    );

    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  @override
  void recordRoundFinished() => _roundsSinceInterstitial++;

  @override
  Future<bool> maybeShowInterstitial() async {
    // مطفأة عند الإطلاق — لا نحمّل إعلاناً ولا نعرضه.
    if (!_interstitialsWanted) return false;
    if (_roundsSinceInterstitial < AppConfig.roundsBetweenInterstitials) {
      return false;
    }

    // سقف زمني صارم فوق سقف الجولات — لا إعلان بينيّ كل دقيقة مهما لعب.
    final last = _lastInterstitialAt;
    if (last != null &&
        DateTime.now().difference(last).inSeconds <
            AppConfig.minSecondsBetweenInterstitials) {
      return false;
    }

    final ad = _interstitial.take();
    if (ad == null) {
      if (_canLoad) _interstitial.load();
      return false;
    }

    _roundsSinceInterstitial = 0;
    _lastInterstitialAt = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (_canLoad && _interstitialsWanted) _interstitial.load();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (_canLoad && _interstitialsWanted) _interstitial.load();
      },
    );

    await ad.show();
    return true;
  }
}
