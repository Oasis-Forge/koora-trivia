import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/datasources/entitlement_local_datasource.dart';
import 'package:football_trivia/data/services/play_billing_service.dart';
import 'package:football_trivia/domain/entities/store_product.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          for (final id in ids)
            ProductDetails(
              id: id,
              title: id,
              description: '',
              price: r'$1',
              rawPrice: 1,
              currencyCode: 'USD',
            ),
        ],
        notFoundIDs: const [],
      );

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
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

  setUp(() {
    store = _FakeStore();
    consumed = [];
    service = PlayBillingService(
      entitlements: _MemoryEntitlements(),
      store: store,
      consume: (purchase) async => consumed.add(purchase.productID),
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
}
