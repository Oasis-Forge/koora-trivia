import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/data/services/ad_consent.dart';
import 'package:football_trivia/data/services/admob_ad_service.dart';
import 'package:football_trivia/domain/repositories/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// موافقة مزيّفة: الاختبار يقرر الحالة ومتى يكتمل النموذج.
class _FakeConsent implements AdConsent {
  _FakeConsent({this.canRequest = false, this.optionsRequired = false});

  bool canRequest;
  bool optionsRequired;

  /// إن وُجد، لا يكتمل نموذج الموافقة حتى يُكمله الاختبار.
  Completer<void>? gate;

  /// `false` يحاكي فشل تحديث الموافقة (انقطاع الاتصال مثلاً).
  bool gatherSucceeds = true;

  /// يحاكي ما يختاره اللاعب داخل نموذج خيارات الخصوصية.
  void Function()? onPrivacyForm;
  bool privacyFormShown = true;
  bool throwOnRead = false;

  int gatherCalls = 0;
  int privacyFormCalls = 0;

  @override
  Future<bool> gather() async {
    gatherCalls++;
    await gate?.future;
    return gatherSucceeds;
  }

  @override
  Future<bool> canRequestAds() async {
    if (throwOnRead) throw StateError('ump');
    return canRequest;
  }

  @override
  Future<bool> isPrivacyOptionsRequired() async => optionsRequired;

  @override
  Future<bool> showPrivacyOptionsForm() async {
    privacyFormCalls++;
    onPrivacyForm?.call();
    return privacyFormShown;
  }
}

/// إعلان مكافأ مزيّف يحاكي ترتيب ردود نداء SDK: المكافأة أثناء العرض، ثم الإغلاق.
class _FakeRewardedAd implements RewardedAd {
  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  OnUserEarnedRewardCallback? _earn;
  int disposeCalls = 0;

  @override
  Future<void> show({
    required OnUserEarnedRewardCallback onUserEarnedReward,
  }) async {
    _earn = onUserEarnedReward;
  }

  @override
  Future<void> dispose() async => disposeCalls++;

  void reward() => _earn!(this, RewardItem(1, 'reward'));

  void dismiss() =>
      fullScreenContentCallback!.onAdDismissedFullScreenContent!(this);

  void failToShow() => fullScreenContentCallback!
      .onAdFailedToShowFullScreenContent!(this, AdError(0, 'test', 'failed'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  _Harness(this.consent, {bool supported = true, Completer<void>? sdkGate}) {
    service = AdMobAdService(
      consent: consent,
      supportedPlatform: supported,
      initializeSdk: () async {
        sdkInits++;
        await sdkGate?.future;
      },
      loadRewarded: (onLoaded, onFailed) {
        rewardedRequests++;
        deliverRewarded = onLoaded;
        failRewarded = onFailed;
      },
      loadInterstitial: (onLoaded, onFailed) => interstitialRequests++,
    )..onChanged = () => changes++;
  }

  final _FakeConsent consent;
  late final AdMobAdService service;

  int sdkInits = 0;
  int rewardedRequests = 0;
  int interstitialRequests = 0;
  int changes = 0;
  void Function(RewardedAd ad)? deliverRewarded;
  void Function(String message)? failRewarded;
}

void main() {
  group('بوابة الموافقة', () {
    test('مستخدم جديد: لا تهيئة ولا طلب إعلان قبل إغلاق نموذج الموافقة', () {
      fakeAsync((async) {
        final consent = _FakeConsent()..gate = Completer<void>();
        final h = _Harness(consent);

        h.service.init();
        async.flushMicrotasks();

        expect(consent.gatherCalls, 1);
        expect(h.sdkInits, 0, reason: 'تهيئة الحزمة قبل الموافقة ممنوعة');
        expect(h.rewardedRequests, 0, reason: 'طلب إعلان قبل الموافقة ممنوع');

        // اختار اللاعب وأُغلق النموذج.
        consent.canRequest = true;
        consent.gate!.complete();
        async.flushMicrotasks();

        expect(h.sdkInits, 1);
        expect(h.rewardedRequests, 1);
      });
    });

    test('موافقة جلسة سابقة: التحميل يبدأ دون انتظار تحديث الموافقة', () {
      fakeAsync((async) {
        final consent = _FakeConsent(canRequest: true)
          ..gate = Completer<void>();
        final h = _Harness(consent);

        h.service.init();
        async.flushMicrotasks();
        expect(h.sdkInits, 1);
        expect(h.rewardedRequests, 1);

        consent.gate!.complete();
        async.flushMicrotasks();

        // لا تهيئة ثانية ولا طلب مكرّر فوق التحميل الجاري.
        expect(h.sdkInits, 1);
        expect(h.rewardedRequests, 1);
      });
    });

    test('موافقة لا تسمح بالإعلانات: لا تحميل عند العودة ولا عند طلب إعلان', () {
      fakeAsync((async) {
        final h = _Harness(_FakeConsent());

        h.service.init();
        async.flushMicrotasks();

        h.service.onAppResumed();
        RewardResult? result;
        h.service.showRewarded().then((r) => result = r);
        async.flushMicrotasks();

        expect(result, RewardResult.unavailable);
        expect(h.sdkInits, 0);
        expect(h.rewardedRequests, 0);
        expect(h.service.isRewardedReady, isFalse);
      });
    });

    test('سحب الموافقة أثناء تهيئة الحزمة يمنع الطلب بعد اكتمالها', () {
      fakeAsync((async) {
        final consent = _FakeConsent(canRequest: true, optionsRequired: true);
        final sdkGate = Completer<void>();
        final h = _Harness(consent, sdkGate: sdkGate);

        h.service.init();
        async.flushMicrotasks();
        expect(h.sdkInits, 1);

        // الحزمة لم تجهز بعد: العودة إلى التطبيق لا تطلب إعلاناً.
        h.service.onAppResumed();
        expect(h.rewardedRequests, 0);

        consent.onPrivacyForm = () => consent.canRequest = false;
        h.service.showPrivacyOptions();
        async.flushMicrotasks();

        sdkGate.complete();
        async.flushMicrotasks();

        expect(h.rewardedRequests, 0);
      });
    });

    test('منصة غير مدعومة: لا موافقة ولا إعلانات', () {
      fakeAsync((async) {
        final consent = _FakeConsent(canRequest: true);
        final h = _Harness(consent, supported: false);

        h.service.init();
        h.service.onAppResumed();
        bool? shown;
        h.service.showPrivacyOptions().then((v) => shown = v);
        async.flushMicrotasks();

        expect(consent.gatherCalls, 0);
        expect(consent.privacyFormCalls, 0);
        expect(shown, isFalse);
        expect(h.rewardedRequests, 0);
      });
    });

    test('init يعمل مرة واحدة مهما تكرر استدعاؤه', () {
      fakeAsync((async) {
        final consent = _FakeConsent(canRequest: true);
        final h = _Harness(consent);

        h.service
          ..init()
          ..init();
        async.flushMicrotasks();

        expect(consent.gatherCalls, 1);
        expect(h.sdkInits, 1);
      });
    });

    test('خطأ في قراءة الموافقة لا يُسقط الإقلاع ولا يطلب إعلاناً', () {
      fakeAsync((async) {
        final h = _Harness(_FakeConsent(canRequest: true)..throwOnRead = true);

        Object? error;
        var done = false;
        h.service.init().then((_) => done = true, onError: (e) => error = e);
        async.flushMicrotasks();

        expect(done, isTrue);
        expect(error, isNull);
        expect(h.rewardedRequests, 0);
      });
    });
  });

  group('إعادة تحديث الموافقة', () {
    test('تحديث فشل عند الإقلاع يُعاد عند العودة إلى التطبيق', () {
      fakeAsync((async) {
        final consent = _FakeConsent()..gatherSucceeds = false;
        final h = _Harness(consent);
        h.service.init();
        async.flushMicrotasks();
        expect(h.rewardedRequests, 0);

        // عاد الاتصال: التحديث ينجح هذه المرة ويسمح بالإعلانات.
        consent
          ..gatherSucceeds = true
          ..canRequest = true;
        h.service.onAppResumed();
        async.flushMicrotasks();

        expect(consent.gatherCalls, 2);
        expect(h.sdkInits, 1);
        expect(h.rewardedRequests, 1);
      });
    });

    test('طلب إعلان بعد فشل التحديث يعيد التحديث أيضاً', () {
      fakeAsync((async) {
        final consent = _FakeConsent()..gatherSucceeds = false;
        final h = _Harness(consent);
        h.service.init();
        async.flushMicrotasks();

        h.service.showRewarded();
        async.flushMicrotasks();

        expect(consent.gatherCalls, 2);
      });
    });

    test('لا يبدأ تحديث ثانٍ والأول جارٍ', () {
      fakeAsync((async) {
        final consent = _FakeConsent()..gatherSucceeds = false;
        final h = _Harness(consent);
        h.service.init();
        async.flushMicrotasks();

        // عرض النموذج نفسه قد يُطلق أحداث عودة متتالية.
        consent.gate = Completer<void>();
        h.service
          ..onAppResumed()
          ..onAppResumed();
        async.flushMicrotasks();
        expect(consent.gatherCalls, 2);

        consent.gate!.complete();
        async.flushMicrotasks();

        // ما زال فاشلاً، والتحديث السابق انتهى: العودة التالية تعيد المحاولة.
        h.service.onAppResumed();
        async.flushMicrotasks();
        expect(consent.gatherCalls, 3);
      });
    });

    test('تحديث نجح وبقيت الإعلانات ممنوعة: لا يُعاد عند كل عودة', () {
      fakeAsync((async) {
        final consent = _FakeConsent();
        final h = _Harness(consent);
        h.service.init();
        async.flushMicrotasks();

        h.service
          ..onAppResumed()
          ..showRewarded();
        async.flushMicrotasks();

        expect(consent.gatherCalls, 1, reason: 'النموذج لا يلاحق اللاعب');
      });
    });
  });

  group('التحميل وإعادة المحاولة', () {
    test('فشل التحميل يُعاد بعد المهلة، والعودة إلى التطبيق تعيده فوراً', () {
      fakeAsync((async) {
        final h = _Harness(_FakeConsent(canRequest: true));
        h.service.init();
        async.flushMicrotasks();
        expect(h.rewardedRequests, 1);

        h.failRewarded!('offline');
        async.elapse(
          Duration(seconds: AppConfig.adRetryDelaysSeconds.first),
        );
        expect(h.rewardedRequests, 2);

        h.failRewarded!('offline');
        h.service.onAppResumed();
        expect(h.rewardedRequests, 3);
      });
    });

    test('طلب إعلان غير جاهز يعيد محاولة التحميل فوراً', () {
      fakeAsync((async) {
        final h = _Harness(_FakeConsent(canRequest: true));
        h.service.init();
        async.flushMicrotasks();
        h.failRewarded!('offline');

        RewardResult? result;
        h.service.showRewarded().then((r) => result = r);
        async.flushMicrotasks();

        expect(result, RewardResult.unavailable);
        expect(h.rewardedRequests, 2);
      });
    });

    test('الإعلان البيني يتبع مفتاح الإطلاق', () {
      fakeAsync((async) {
        final h = _Harness(_FakeConsent(canRequest: true));
        h.service.init();
        async.flushMicrotasks();
        h.service.onAppResumed();

        expect(h.interstitialRequests, AppConfig.interstitialsEnabled ? 1 : 0);
      });
    });
  });

  group('خيارات الخصوصية', () {
    test('المدخل يتبع الموافقة ويُخطر الواجهة', () {
      fakeAsync((async) {
        final h = _Harness(
          _FakeConsent(canRequest: true, optionsRequired: true),
        );
        expect(h.service.isPrivacyOptionsRequired, isFalse);

        h.service.init();
        async.flushMicrotasks();

        expect(h.service.isPrivacyOptionsRequired, isTrue);
        expect(h.changes, greaterThan(0));
      });
    });

    test('تغيير الموافقة من النموذج يُطبَّق فوراً في الاتجاهين', () {
      fakeAsync((async) {
        final consent = _FakeConsent(canRequest: true, optionsRequired: true);
        final h = _Harness(consent);
        h.service.init();
        async.flushMicrotasks();
        expect(h.rewardedRequests, 1);

        // أوقف اللاعب الإعلانات من النموذج: لا تحميل بعدها حتى عند العودة.
        consent.onPrivacyForm = () => consent.canRequest = false;
        bool? shown;
        h.service.showPrivacyOptions().then((v) => shown = v);
        async.flushMicrotasks();

        expect(shown, isTrue);
        expect(consent.privacyFormCalls, 1);
        h.failRewarded!('late');
        h.service.onAppResumed();
        async.elapse(const Duration(minutes: 10));
        expect(h.rewardedRequests, 1);

        // ثم سمح بها مجدداً: يعود التحميل دون إعادة تشغيل التطبيق.
        consent.onPrivacyForm = () => consent.canRequest = true;
        h.service.showPrivacyOptions();
        async.flushMicrotasks();
        expect(h.rewardedRequests, 2);
        expect(h.sdkInits, 1);
      });
    });

    test('تعذّر عرض النموذج يعيد false', () {
      fakeAsync((async) {
        final consent = _FakeConsent(canRequest: true)
          ..privacyFormShown = false;
        final h = _Harness(consent);

        bool? shown;
        h.service.showPrivacyOptions().then((v) => shown = v);
        async.flushMicrotasks();

        expect(shown, isFalse);
      });
    });
  });

  group('عرض الإعلان المكافأ', () {
    /// خدمة مسموح لها بالإعلانات، وقد وصلها إعلان جاهز.
    (_Harness, _FakeRewardedAd) loadedService(FakeAsync async) {
      final h = _Harness(_FakeConsent(canRequest: true));
      h.service.init();
      async.flushMicrotasks();
      final ad = _FakeRewardedAd();
      h.deliverRewarded!(ad);
      return (h, ad);
    }

    test('اكتمال التحميل يجعل الخدمة جاهزة ويُخطر الواجهة', () {
      fakeAsync((async) {
        final h = _Harness(_FakeConsent(canRequest: true));
        h.service.init();
        async.flushMicrotasks();
        final before = h.changes;
        expect(h.service.isRewardedReady, isFalse);

        h.deliverRewarded!(_FakeRewardedAd());

        expect(h.service.isRewardedReady, isTrue);
        expect(h.changes, before + 1);
      });
    });

    test('النتيجة تُحسم عند الإغلاق لا عند العرض، ثم يُحمَّل إعلان جديد', () {
      fakeAsync((async) {
        final (h, ad) = loadedService(async);

        RewardResult? result;
        h.service.showRewarded().then((r) => result = r);
        async.flushMicrotasks();

        // هنا بالضبط كان خطأ 8 سبتمبر: النتيجة حُسمت قبل وصول المكافأة.
        expect(result, isNull);
        expect(h.service.isRewardedReady, isFalse);

        ad.reward();
        async.flushMicrotasks();
        expect(result, isNull);

        ad.dismiss();
        async.flushMicrotasks();

        expect(result, RewardResult.earned);
        expect(ad.disposeCalls, 1);
        expect(h.rewardedRequests, 2);
      });
    });

    test('إغلاق الإعلان قبل المكافأة يعيد dismissed', () {
      fakeAsync((async) {
        final (h, ad) = loadedService(async);

        RewardResult? result;
        h.service.showRewarded().then((r) => result = r);
        async.flushMicrotasks();
        ad.dismiss();
        async.flushMicrotasks();

        expect(result, RewardResult.dismissed);
        expect(h.rewardedRequests, 2);
      });
    });

    test('فشل عرض الإعلان يعيد unavailable ويعيد التحميل', () {
      fakeAsync((async) {
        final (h, ad) = loadedService(async);

        RewardResult? result;
        h.service.showRewarded().then((r) => result = r);
        async.flushMicrotasks();
        ad.failToShow();
        async.flushMicrotasks();

        expect(result, RewardResult.unavailable);
        expect(ad.disposeCalls, 1);
        expect(h.rewardedRequests, 2);
      });
    });
  });
}
