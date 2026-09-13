import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/repositories/ad_service.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';

import 'fakes/fake_ad_service.dart';

class _FakeEconomyRepo implements EconomyRepository {
  _FakeEconomyRepo([this.economy = const Economy()]);
  Economy economy;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async => economy = value;
}

void main() {
  group('AdsProvider', () {
    test('الإعلان المكتمل يعيد earned', () async {
      final service = FakeAdService();
      final ads = AdsProvider(service: service);

      expect(await ads.showRewarded(), RewardResult.earned);
      expect(service.showRewardedCalls, 1);
    });

    test('الإغلاق المبكر يعيد dismissed لا earned', () async {
      final ads = AdsProvider(
        service: FakeAdService(result: RewardResult.dismissed),
      );

      expect(await ads.showRewarded(), RewardResult.dismissed);
    });

    test('لا يُعرض إعلانان في وقت واحد', () async {
      final service = FakeAdService();
      final ads = AdsProvider(service: service);

      // الاستدعاء الثاني أثناء العرض يُرفض.
      final first = ads.showRewarded();
      final second = await ads.showRewarded();
      await first;

      expect(second, RewardResult.unavailable);
      expect(service.showRewardedCalls, 1);
    });

    test('عدم جاهزية الإعلان تظهر في isReady', () {
      final ads = AdsProvider(service: FakeAdService(ready: false));
      expect(ads.isReady, isFalse);
    });

    test('اكتمال تحميل الإعلان يُخطر الواجهة', () {
      final service = FakeAdService(ready: false);
      final ads = AdsProvider(service: service);
      var notified = 0;
      ads.addListener(() => notified++);

      service.setReady(true);

      expect(notified, 1);
      expect(ads.isReady, isTrue);
    });

    test('خيارات الخصوصية تمرّ إلى الخدمة', () async {
      final service = FakeAdService(
        privacyOptionsRequired: true,
        privacyFormShown: false,
      );
      final ads = AdsProvider(service: service);

      expect(ads.isPrivacyOptionsRequired, isTrue);
      expect(await ads.showPrivacyOptions(), isFalse);
      expect(service.privacyFormCalls, 1);
    });

    test('العودة إلى التطبيق تُمرَّر إلى الخدمة', () {
      final service = FakeAdService();
      AdsProvider(service: service).onAppResumed();

      expect(service.resumeCalls, 1);
    });

    test('إتلاف المزوّد يفصله عن الخدمة', () {
      final service = FakeAdService(ready: false);
      AdsProvider(service: service).dispose();

      expect(service.listener, isNull);
      // إخطار بعد الإتلاف كان سيرمي خطأ لو بقي المستمع موصولاً.
      expect(() => service.setReady(true), returnsNormally);
    });
  });

  group('الإعلان البيني', () {
    test('لا يظهر قبل اكتمال عدد الجولات', () async {
      final service = FakeAdService();
      final ads = AdsProvider(service: service);

      for (var i = 0; i < AppConfig.roundsBetweenInterstitials - 1; i++) {
        ads.recordRoundFinished();
        expect(await ads.maybeShowInterstitial(), isFalse);
      }
      expect(service.interstitialsShown, 0);
    });

    test('يظهر عند بلوغ عدد الجولات ثم يُعاد العدّ', () async {
      final service = FakeAdService();
      final ads = AdsProvider(service: service);

      for (var i = 0; i < AppConfig.roundsBetweenInterstitials; i++) {
        ads.recordRoundFinished();
      }

      expect(await ads.maybeShowInterstitial(), isTrue);
      expect(service.interstitialsShown, 1);

      // العدّاد صُفِّر — الجولة التالية لا تكفي وحدها.
      ads.recordRoundFinished();
      expect(await ads.maybeShowInterstitial(), isFalse);
    });

    test('إزالة الإعلانات توقف البينيّ', () async {
      final service = FakeAdService();
      final ads = AdsProvider(service: service)..adsRemoved = true;

      for (var i = 0; i < AppConfig.roundsBetweenInterstitials * 2; i++) {
        ads.recordRoundFinished();
      }

      expect(await ads.maybeShowInterstitial(), isFalse);
      expect(service.interstitialsShown, 0);
    });
  });

  group('مكافآت الإعلان', () {
    test('الإعلان يمنح قلباً واحداً ويستهلك من الحد اليومي', () async {
      final provider = EconomyProvider(
        repository: _FakeEconomyRepo(
          Economy(
            hearts: 1,
            lastRegenAtIso: DateTime.now().toIso8601String(),
          ),
        ),
      );
      await provider.init();

      final before = provider.rewardedRefillsLeft;
      expect(await provider.grantRewardedHearts(), isTrue);

      expect(provider.hearts, 1 + AppConfig.heartsPerRewardedAdWatch);
      expect(provider.rewardedRefillsLeft, before - 1);
    });

    test('عملات الإعلان تسدّ الفجوة بين دخل اليوم وسعر الشراء', () async {
      final provider = EconomyProvider(repository: _FakeEconomyRepo());
      await provider.init();

      await provider.grantRewardedCoins();
      expect(provider.coins, AppConfig.coinsPerRewardedAd);

      // دخل اليوم + إعلان واحد يجب أن يكفي لشراء واحد.
      const daily = AppConfig.coinsTaskAnswers +
          AppConfig.coinsTaskDaily +
          AppConfig.coinsTaskLevel +
          AppConfig.coinsChestBonus;

      expect(
        daily + AppConfig.coinsPerRewardedAd,
        greaterThanOrEqualTo(AppConfig.priceHeartsRefill),
        reason: 'الإعلان يجب أن يجعل الشراء ممكناً في نفس اليوم، وإلا فلا سبب '
            'لمشاهدته',
      );
    });

    test('عملات الإعلان بلا حدّ يومي', () async {
      final provider = EconomyProvider(repository: _FakeEconomyRepo());
      await provider.init();

      for (var i = 0; i < 6; i++) {
        await provider.grantRewardedCoins();
      }
      expect(provider.coins, AppConfig.coinsPerRewardedAd * 6);
    });
  });
}
