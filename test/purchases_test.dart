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

/// اقتصاد برصيد قلوب محدّد ووقت تجديد حديث.
Future<EconomyProvider> _economy({int hearts = 5}) async {
  final provider = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(hearts: hearts, lastRegenAtIso: DateTime.now().toIso8601String()),
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
    grantHearts: economy.grantPurchasedHearts,
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
      expect(await w.purchases.buy(StoreProductKind.heartsSmall),
          PurchaseOutcome.unavailable);
    });

    test('حزمة القلوب تُضاف فوق السقف', () async {
      // من دفع وهو يملك أربعة قلوب لا يجوز أن يحصل على قلب واحد.
      final economy = await _economy(hearts: 4);
      final w = _wire(FakeBillingService(), economy);
      await w.purchases.init();

      expect(await w.purchases.buy(StoreProductKind.heartsLarge),
          PurchaseOutcome.purchased);

      expect(economy.hearts, 4 + AppConfig.heartsPerLargePack);
      expect(economy.hearts, greaterThan(AppConfig.maxHearts));
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
    });

    test('شراء ملغى لا يمنح شيئاً', () async {
      final economy = await _economy(hearts: 2);
      final w = _wire(
        FakeBillingService(outcome: PurchaseOutcome.cancelled),
        economy,
      );
      await w.purchases.init();

      expect(await w.purchases.buy(StoreProductKind.heartsSmall),
          PurchaseOutcome.cancelled);
      expect(economy.hearts, 2);
    });

    test('دفع معلّق لا يُسلّم قبل اكتماله', () async {
      // تحويل بنكي أو موافقة ولي أمر: يصل لاحقاً عبر مجرى المشتريات.
      final economy = await _economy(hearts: 1);
      final w = _wire(
        FakeBillingService(outcome: PurchaseOutcome.pending),
        economy,
      );
      await w.purchases.init();

      expect(await w.purchases.buy(StoreProductKind.heartsSmall),
          PurchaseOutcome.pending);
      expect(economy.hearts, 1);
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

    test('المستهلَكات لا تُستعاد', () async {
      // قلوب اشتُريت واستُهلكت لا تُمنح ثانية عند كل إقلاع.
      final economy = await _economy(hearts: 3);
      final billing = FakeBillingService(
        restoredAtInit: const [StoreProductKind.removeAds],
      );
      final w = _wire(billing, economy);

      await w.purchases.init();

      expect(economy.hearts, 3);
    });
  });
}
