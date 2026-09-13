import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/repositories/ad_service.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';

class _FakeAdService implements AdService {
  _FakeAdService({this.ready = true, this.result = RewardResult.earned});

  bool ready;
  RewardResult result;

  bool adsRemovedValue = false;
  int showRewardedCalls = 0;
  int interstitialsShown = 0;
  int rounds = 0;

  @override
  Future<void> init() async {}

  @override
  bool get isRewardedReady => ready;

  @override
  Future<RewardResult> showRewarded() async {
    showRewardedCalls++;
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
    interstitialsShown++;
    return true;
  }

  @override
  set adsRemoved(bool value) => adsRemovedValue = value;
}

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
      final service = _FakeAdService();
      final ads = AdsProvider(service: service);

      expect(await ads.showRewarded(), RewardResult.earned);
      expect(service.showRewardedCalls, 1);
    });

    test('الإغلاق المبكر يعيد dismissed لا earned', () async {
      final ads = AdsProvider(
        service: _FakeAdService(result: RewardResult.dismissed),
      );

      expect(await ads.showRewarded(), RewardResult.dismissed);
    });

    test('لا يُعرض إعلانان في وقت واحد', () async {
      final service = _FakeAdService();
      final ads = AdsProvider(service: service);

      // الاستدعاء الثاني أثناء العرض يُرفض.
      final first = ads.showRewarded();
      final second = await ads.showRewarded();
      await first;

      expect(second, RewardResult.unavailable);
      expect(service.showRewardedCalls, 1);
    });

    test('عدم جاهزية الإعلان تظهر في isReady', () {
      final ads = AdsProvider(service: _FakeAdService(ready: false));
      expect(ads.isReady, isFalse);
    });
  });

  group('الإعلان البيني', () {
    test('لا يظهر قبل اكتمال عدد الجولات', () async {
      final service = _FakeAdService();
      final ads = AdsProvider(service: service);

      for (var i = 0; i < AppConfig.roundsBetweenInterstitials - 1; i++) {
        ads.recordRoundFinished();
        expect(await ads.maybeShowInterstitial(), isFalse);
      }
      expect(service.interstitialsShown, 0);
    });

    test('يظهر عند بلوغ عدد الجولات ثم يُعاد العدّ', () async {
      final service = _FakeAdService();
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
      final service = _FakeAdService();
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
