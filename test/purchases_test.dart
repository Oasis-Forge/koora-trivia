import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/store_product.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/purchases_provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_billing_service.dart';
import 'fakes/fake_repositories.dart';

/// اقتصاد برصيد محدّد ووقت تجديد حديث.
Future<EconomyProvider> _economy({int hearts = 5, int coins = 0}) async {
  final provider = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(
        hearts: hearts,
        coins: coins,
        lastRegenAtIso: DateTime.now().toIso8601String(),
      ),
    ),
  );
  await provider.init();
  return provider;
}

/// يربط المتجر المزيّف بالاقتصاد والإعلانات كما يفعل `app.dart`.
({PurchasesProvider purchases, EconomyProvider economy, FakeAdService ads})
    _wire(FakeBillingService billing, EconomyProvider economy) {
  final adService = FakeAdService(bannersAllowed: true);
  final ads = AdsProvider(service: adService);
  final purchases = PurchasesProvider(
    service: billing,
    grantCoins: economy.grantPurchasedCoins,
    onAdsRemoved: () => ads.adsRemoved = true,
  );
  return (purchases: purchases, economy: economy, ads: adService);
}

void main() {
  group('الشراء داخل التطبيق', () {
    test('المتجر غير متاح حتى يردّ بمنتجاته', () async {
      // ملف الدفع تحت التحقق أو المنتجات لم تُنشأ بعد: الشاشة تعرض «قريباً»
      // بدل صفوف شراء لا تعمل. هذا ما يسمح بشحن الكود قبل اكتمال الإعداد.
      final billing = FakeBillingService(available: false);
      final w = _wire(billing, await _economy());
      await w.purchases.init();

      expect(w.purchases.isAvailable, isFalse);
      expect(w.purchases.products, isEmpty);
      expect(await w.purchases.buy(StoreProductKind.coinsSmall),
          PurchaseOutcome.unavailable);
    });

    test('حزمة العملات تُضاف إلى الرصيد', () async {
      final economy = await _economy(coins: 30);
      final w = _wire(FakeBillingService(), economy);
      await w.purchases.init();

      expect(await w.purchases.buy(StoreProductKind.coinsSmall),
          PurchaseOutcome.purchased);

      expect(economy.coins, 30 + AppConfig.coinsPerSmallPack);
    });

    test('العملات المشتراة لا ترفع القلوب فوق السقف', () async {
      // قرار المالك: نبيع عملات لا قلوباً، والقلوب لا تتجاوز خمسة مهما دفع
      // اللاعب. ملء القلوب يتوقف عند السقف، ويُمنع شراؤه والرصيد ممتلئ.
      final economy = await _economy(hearts: 2, coins: 300);
      final w = _wire(FakeBillingService(), economy);
      await w.purchases.init();
      await w.purchases.buy(StoreProductKind.coinsSmall);

      expect(await economy.buyHeartsRefill(), isTrue);
      expect(economy.hearts, AppConfig.maxHearts);

      // ما زال معه ما يكفي لملء آخر؛ المنع سببه الامتلاء وحده.
      expect(economy.coins, greaterThanOrEqualTo(AppConfig.priceHeartsRefill));
      expect(economy.canBuyHeartsRefill, isFalse);
      expect(await economy.buyHeartsRefill(), isFalse);
      expect(economy.hearts, AppConfig.maxHearts);
    });

    test('إزالة الإعلانات توقف الشريط والبينية معاً', () async {
      final w = _wire(FakeBillingService(), await _economy());
      await w.purchases.init();
      expect(w.ads.areBannersAllowed, isTrue);

      await w.purchases.buy(StoreProductKind.removeAds);

      expect(w.purchases.adsRemoved, isTrue);
      expect(w.ads.adsRemovedValue, isTrue);
      expect(w.ads.areBannersAllowed, isFalse);
      expect(await w.ads.maybeShowInterstitial(), isFalse);
      expect(w.economy.coins, 0, reason: 'الإزالة المستقلة بلا عملات');
    });

    test('الباقة تزيل الإعلانات وتمنح عملاتها', () async {
      final economy = await _economy(coins: 20);
      final w = _wire(FakeBillingService(), economy);
      await w.purchases.init();

      await w.purchases.buy(StoreProductKind.removeAdsBundle);

      expect(w.purchases.adsRemoved, isTrue);
      expect(w.ads.areBannersAllowed, isFalse);
      expect(economy.coins, 20 + AppConfig.coinsInRemoveAdsBundle);
    });

    test('استعادة الباقة تعيد إزالة الإعلانات دون عملاتها', () async {
      // مسح البيانات ثم الاستعادة كان سيصبح طريقاً لعملات مجانية بلا حد.
      final economy = await _economy(coins: 40);
      final w = _wire(
        FakeBillingService(
          restoredAtInit: const [StoreProductKind.removeAdsBundle],
        ),
        economy,
      );

      await w.purchases.init();

      expect(w.purchases.adsRemoved, isTrue);
      expect(economy.coins, 40);
    });

    test('شراء ملغى لا يمنح شيئاً', () async {
      final economy = await _economy(coins: 10);
      final w = _wire(
        FakeBillingService(outcome: PurchaseOutcome.cancelled),
        economy,
      );
      await w.purchases.init();

      expect(await w.purchases.buy(StoreProductKind.coinsSmall),
          PurchaseOutcome.cancelled);
      expect(economy.coins, 10);
    });

    test('دفع معلّق لا يُسلّم قبل اكتماله', () async {
      // تحويل بنكي أو موافقة ولي أمر: يصل لاحقاً عبر مجرى المشتريات.
      final economy = await _economy(coins: 10);
      final w = _wire(
        FakeBillingService(outcome: PurchaseOutcome.pending),
        economy,
      );
      await w.purchases.init();

      expect(await w.purchases.buy(StoreProductKind.coinsSmall),
          PurchaseOutcome.pending);
      expect(economy.coins, 10);
    });

    test('شراء سابق يُستعاد عند الإقلاع فتبقى الإعلانات مطفأة', () async {
      // جهاز جديد أو إعادة تثبيت: الاستحقاق من Play لا من رمز النسخة.
      final billing = FakeBillingService(
        restoredAtInit: const [StoreProductKind.removeAds],
      );
      final w = _wire(billing, await _economy());

      await w.purchases.init();

      expect(w.purchases.adsRemoved, isTrue);
      expect(w.ads.adsRemovedValue, isTrue);
    });

    test('الاستعادة تعيد صفراً حين لا مشتريات سابقة', () async {
      final billing = FakeBillingService();
      final w = _wire(billing, await _economy());
      await w.purchases.init();

      expect(await w.purchases.restore(), 0);
      expect(billing.restoreCalls, 1);
    });

    test('استعادة إزالة الإعلانات لا تمنح عملات', () async {
      // العملات المشتراة واستُهلكت لا تُمنح ثانية عند كل إقلاع.
      final economy = await _economy(coins: 40);
      final billing = FakeBillingService(
        restoredAtInit: const [StoreProductKind.removeAds],
      );
      final w = _wire(billing, economy);

      await w.purchases.init();

      expect(economy.coins, 40);
    });
  });
}
