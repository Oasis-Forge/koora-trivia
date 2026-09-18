import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/datasources/entitlement_local_datasource.dart';
import 'package:football_trivia/data/services/play_billing_service.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/store_product.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'fakes/fake_repositories.dart';

class _MemoryEntitlements implements EntitlementLocalDataSource {
  bool value = false;

  @override
  Future<bool> readAdsRemoved() async => value;

  @override
  Future<void> writeAdsRemoved(bool v) async => value = v;
}

/// متجر Play مزيّف بسلوك إضافة `in_app_purchase_android` 0.5.3 نفسه: الشراء الحيّ
/// يصل `purchased`، وكل ما تعيده الاستعادة يصل `restored` — مُقرّاً كان أو لا.
class _FakeStore implements InAppPurchase {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  List<PurchaseDetails> owned = [];

  /// Play Billing متصل؟ `false` يحاكي هاتفاً لم يردّ متجره عند الإقلاع.
  bool available = true;

  /// منتجات لا تعرفها Play بعد (غير مفعّلة أو لم تصل الجهاز).
  Set<String> missing = {};
  int queries = 0;
  int restores = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queries++;
    return ProductDetailsResponse(
        productDetails: [
          for (final id in ids.difference(missing))
            ProductDetails(
              id: id,
              title: id,
              description: '',
              price: r'$1',
              rawPrice: 1,
              currencyCode: 'USD',
            ),
        ],
        notFoundIDs: missing.intersection(ids).toList(),
      );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
    controller.add([
      for (final p in owned) p..status = PurchaseStatus.restored,
    ]);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// شراء كما تصفه Play: غير المُقرّ ينتظر `completePurchase`.
PurchaseDetails _purchase(StoreProductKind kind, {required bool acknowledged}) =>
    PurchaseDetails(
      purchaseID: 'order-${kind.id}',
      productID: kind.id,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'token-${kind.id}',
        source: 'google_play',
      ),
      transactionDate: '0',
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = !acknowledged;

void main() {
  late _FakeStore store;
  late PlayBillingService service;
  late List<(StoreProductKind, bool)> deliveries;
  late List<String> consumed;
  late FakeErrorLog errorLog;
  late DateTime now;

  setUp(() {
    store = _FakeStore();
    consumed = [];
    errorLog = FakeErrorLog();
    now = DateTime(2026, 9, 19, 12);
    service = PlayBillingService(
      entitlements: _MemoryEntitlements(),
      errorLog: errorLog,
      store: store,
      consume: (purchase) async => consumed.add(purchase.productID),
      clock: () => now,
    );
    deliveries = [];
    service.onDelivered = (kind, {required bool alreadyDelivered}) =>
        deliveries.add((kind, alreadyDelivered));
  });

  tearDown(() => store.controller.close());

  /// يترك مجرى المشتريات يوصل أحداثه ويكمل التسليم.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('تسليم المشتريات', () {
    test('باقة لم يصل حدث شرائها تُسلَّم كاملة عند الإقلاع التالي', () async {
      // أُغلق التطبيق أثناء نافذة الدفع (أو اكتمل دفع معلّق وهو مغلق): لم يصل
      // `purchased`، ووصل الشراء مع الاستعادة غير مُقرّ. كان يُعامل كاستعادة،
      // فتُزال الإعلانات ولا تُمنح الـ 500 عملة — ما رآه المالك في 19 سبتمبر 2026.
      store.owned = [
        _purchase(StoreProductKind.removeAdsBundle, acknowledged: false),
      ];

      await service.init();
      await settle();

      expect(deliveries, [(StoreProductKind.removeAdsBundle, false)]);
      expect(store.completed, [StoreProductKind.removeAdsBundle.id]);
    });

    test('باقة سُلّمت وأُقرّت سابقاً تعيد إزالة الإعلانات وحدها', () async {
      // جهاز جديد أو مسح البيانات: العملات لا تُمنح ثانية.
      store.owned = [
        _purchase(StoreProductKind.removeAdsBundle, acknowledged: true),
      ];

      await service.init();
      await settle();

      expect(deliveries, [(StoreProductKind.removeAdsBundle, true)]);
      expect(service.adsRemoved, isTrue);
    });

    test('حزمة عملات لم يصل حدث شرائها تُسلَّم عند الإقلاع التالي', () async {
      // كانت المستهلَكات تُتجاهل في الاستعادة كلها: دفع اللاعب ولم يأخذ شيئاً.
      store.owned = [
        _purchase(StoreProductKind.coinsSmall, acknowledged: false),
      ];

      await service.init();
      await settle();

      expect(deliveries, [(StoreProductKind.coinsSmall, false)]);
      // الاستهلاك التلقائي فاته، فيُستهلك هنا وإلا رفضت Play شراءه ثانية.
      expect(consumed, [StoreProductKind.coinsSmall.id]);
    });

    test('حزمة عملات سُلّمت وأُقرّت ولم تُستهلك: تُستهلك دون تسليم ثانٍ', () async {
      store.owned = [
        _purchase(StoreProductKind.coinsSmall, acknowledged: true),
      ];

      await service.init();
      await settle();

      expect(deliveries, isEmpty);
      expect(consumed, [StoreProductKind.coinsSmall.id]);
    });

    test('حزمة العملات في الشراء الحيّ يستهلكها الشراء نفسه', () async {
      await service.init();
      await settle();

      store.controller.add([
        _purchase(StoreProductKind.coinsSmall, acknowledged: false),
      ]);
      await settle();

      expect(deliveries, [(StoreProductKind.coinsSmall, false)]);
      // `buyConsumable(autoConsume: true)` يستهلكه قبل أن يصلنا الحدث.
      expect(consumed, isEmpty);
      expect(store.completed, [StoreProductKind.coinsSmall.id]);
    });

    test('الشراء الحيّ يُسلَّم جديداً', () async {
      await service.init();
      await settle();

      store.controller.add([
        _purchase(StoreProductKind.removeAdsBundle, acknowledged: false),
      ]);
      await settle();

      expect(deliveries, [(StoreProductKind.removeAdsBundle, false)]);
    });
  });

  group('إعادة جلب المنتجات', () {
    const retry = Duration(seconds: AppConfig.billingRetrySeconds);

    test('متجر لم يردّ عند الإقلاع يُطلب ثانية بعد المهلة', () async {
      // ما حدث على هاتف المالك: المتجر على «قريباً» حتى يُغلق التطبيق كاملاً.
      store.available = false;
      await service.init();
      expect(service.isAvailable, isFalse);
      expect(errorLog.entries.single.message, contains('Billing unavailable'));

      store.available = true;
      now = now.add(retry);
      await service.refresh();
      await settle();

      expect(service.isAvailable, isTrue);
      expect(service.products, hasLength(StoreProductKind.values.length));
      // المشتريات السابقة لم تُقرأ عند الإقلاع، فتُقرأ الآن.
      expect(store.restores, 1);
    });

    test('لا محاولة قبل انقضاء المهلة', () async {
      store.available = false;
      await service.init();

      store.available = true;
      now = now.add(retry - const Duration(seconds: 1));
      await service.refresh();

      expect(service.isAvailable, isFalse);
      expect(store.queries, 0);
    });

    test('لا طلب جديد والمتجر محمّل', () async {
      await service.init();
      await settle();
      final before = store.queries;

      now = now.add(retry * 10);
      await service.refresh();

      expect(store.queries, before);
      expect(store.restores, 1);
    });

    test('منتج ناقص يُطلب ثانية ويُسمّى في السجل مرة واحدة', () async {
      // ما يصل مع رسالة الملاحظات فيقول لماذا بقي المتجر على «قريباً».
      store.missing = {StoreProductKind.removeAdsBundle.id};
      await service.init();
      now = now.add(retry);
      await service.refresh();

      expect(store.queries, 2, reason: 'منتج ناقص يُطلب ثانية');
      final messages = errorLog.entries.map((e) => e.message).toList();
      expect(messages, hasLength(1), reason: 'المشكلة نفسها لا تتكرر');
      expect(messages.single, contains('not found: remove_ads_bundle'));

      // وصل المنتج الناقص.
      store.missing = {};
      now = now.add(retry);
      await service.refresh();
      expect(service.products, hasLength(StoreProductKind.values.length));
    });
  });
}
