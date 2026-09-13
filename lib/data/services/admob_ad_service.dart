import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/app_config.dart';
import '../../domain/repositories/ad_service.dart';

/// تنفيذ الإعلانات عبر AdMob.
///
/// معرّفات الإنتاج مضبوطة (حساب Oasis Forge · تطبيق Koora Trivia). الاختيار بين
/// الاختبار والإنتاج يتم في `Injector` عبر `useTestIds: !kReleaseMode`: بناء
/// التطوير يستخدم معرّفات غوغل التجريبية، وبناء الإصدار يستخدم معرّفاتك الحقيقية.
///
/// ⚠️ **لا تنقر على إعلان حقيقي بمعرّفك — يُعرّض الحساب للإيقاف.** لهذا يبقى
/// بناء التطوير على معرّفات الاختبار دائماً.
///
/// المتبقي قبل تفعيل الإعلانات كاملةً: نشر `app-ads.txt` على موقعك المُعلَن.
class AdMobAdService implements AdService {
  AdMobAdService({this.useTestIds = true});

  final bool useTestIds;

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

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;

  bool _initialized = false;
  bool _adsRemoved = false;
  int _roundsSinceInterstitial = 0;
  DateTime? _lastInterstitialAt;

  @override
  set adsRemoved(bool value) => _adsRemoved = value;

  @override
  bool get isRewardedReady => _rewarded != null;

  @override
  Future<void> init() async {
    if (_initialized) return;
    // الإعلانات على أندرويد فقط في هذا الإصدار.
    if (!Platform.isAndroid) return;

    _requestConsent();
    await MobileAds.instance.initialize();
    _initialized = true;

    _loadRewarded();
    _loadInterstitial();
  }

  /// موافقة الخصوصية عبر UMP — إلزامية لتخصيص الإعلانات.
  ///
  /// الاستدعاء غير متزامن عبر ردود نداء لا عبر `Future`، ولا ننتظره: الإعلانات
  /// تُحمَّل بعده مباشرة وستكون غير مخصّصة إن لم تكتمل الموافقة بعد.
  void _requestConsent() {
    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        // النموذج نفسه يقرر هل الموافقة مطلوبة أصلاً (المستخدمون في أوروبا
        // مثلاً)، فلا حاجة لفحص التوفّر يدوياً.
        () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint('تعذّر عرض نموذج الموافقة: ${error.message}');
          }
        }),
        (error) => debugPrint('تعذّر تحديث حالة الموافقة: ${error.message}'),
      );
    } catch (e) {
      // لا نُسقط الإقلاع بسبب الموافقة — الإعلانات غير المخصّصة أفضل من تعطّل.
      debugPrint('خطأ في طلب الموافقة: $e');
    }
  }

  void _loadRewarded() {
    if (!_initialized) return;

    RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        // الفشل شائع عند انقطاع الاتصال — نتركه فارغاً ونعيد المحاولة لاحقاً.
        onAdFailedToLoad: (error) {
          _rewarded = null;
          debugPrint('تعذّر تحميل الإعلان المكافأ: ${error.message}');
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (!AppConfig.interstitialsEnabled) return;
    if (!_initialized || _adsRemoved) return;

    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('تعذّر تحميل الإعلان البيني: ${error.message}');
        },
      ),
    );
  }

  @override
  Future<RewardResult> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      // نحاول التحميل للمرة القادمة قبل أن نعتذر.
      _loadRewarded();
      return RewardResult.unavailable;
    }

    _rewarded = null;
    var earned = false;
    // `ad.show` يكتمل عند *عرض* الإعلان لا عند إغلاقه، بينما مكافأة المستخدم
    // تصل عبر ردّ نداء لاحق. لذا ننتظر الإغلاق عبر Completer ثم نقرر النتيجة —
    // وإلا لعاد الاستدعاء دائماً بـ dismissed ولما مُنحت المكافأة أبداً.
    final completer = Completer<RewardResult>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!completer.isCompleted) {
          completer.complete(
            earned ? RewardResult.earned : RewardResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewarded();
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
    if (!AppConfig.interstitialsEnabled) return false;
    if (_adsRemoved) return false;
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

    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }

    _interstitial = null;
    _roundsSinceInterstitial = 0;
    _lastInterstitialAt = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );

    await ad.show();
    return true;
  }
}
