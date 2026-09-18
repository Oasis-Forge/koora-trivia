import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/store_product.dart';
import '../../domain/repositories/billing_service.dart';
import '../datasources/entitlement_local_datasource.dart';

/// تنفيذ الشراء داخل التطبيق عبر Google Play Billing.
///
/// **المنتجات تُنشأ في Play Console بنفس معرّفات [StoreProductKind].** ما دامت
/// غير منشأة — أو ما دام ملف الدفع تحت التحقق — يعيد المتجر قائمة فارغة،
/// فيبقى [isAvailable] خطأً وتعرض شاشة المتجر «قريباً» كما كانت. لهذا يمكن شحن
/// هذا الكود قبل أن يكتمل إعداد الدفع.
class PlayBillingService implements BillingService {
  PlayBillingService({
    required EntitlementLocalDataSource entitlements,
    InAppPurchase? store,
  })  : _entitlements = entitlements,
        _store = store ?? InAppPurchase.instance;

  final EntitlementLocalDataSource _entitlements;
  final InAppPurchase _store;

  final Map<StoreProductKind, ProductDetails> _details = {};
  final Map<String, Completer<PurchaseOutcome>> _pending = {};

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  void Function()? _onChanged;
  void Function(StoreProductKind kind)? _onDelivered;
  bool _storeAvailable = false;
  bool _adsRemoved = false;
  int _restored = 0;

  @override
  set onChanged(void Function()? listener) => _onChanged = listener;

  @override
  set onDelivered(void Function(StoreProductKind kind)? listener) =>
      _onDelivered = listener;

  @override
  bool get isAvailable => _storeAvailable && _details.isNotEmpty;

  @override
  bool get adsRemoved => _adsRemoved;

  @override
  List<StoreProduct> get products => [
        for (final kind in StoreProductKind.values)
          if (_details[kind] case final d?)
            StoreProduct(kind: kind, title: d.title, price: d.price),
      ];

  @override
  Future<void> init() async {
    // النسخة المحلية أولاً: من اشترى الإزالة يجب ألا يرى إعلاناً لثوانٍ ريثما
    // يردّ المتجر، ولا أن يراها كلها حين يكون بلا اتصال.
    _adsRemoved = await _entitlements.readAdsRemoved();
    if (_adsRemoved) _notify();

    try {
      _storeAvailable = await _store.isAvailable();
      if (!_storeAvailable) return;

      _subscription = _store.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => debugPrint('خطأ في مجرى المشتريات: $e'),
      );

      final response = await _store.queryProductDetails(
        {for (final kind in StoreProductKind.values) kind.id},
      );
      for (final d in response.productDetails) {
        final kind = StoreProductKind.fromId(d.id);
        if (kind != null) _details[kind] = d;
      }

      // مشتريات سابقة (جهاز جديد أو إعادة تثبيت) تصل عبر المجرى نفسه.
      await _store.restorePurchases();
    } catch (e) {
      // متجر غير متاح لا يُسقط الإقلاع: يبقى التطبيق يعمل بلا مشتريات.
      debugPrint('تعذّر بدء المتجر: $e');
    }
    _notify();
  }

  @override
  Future<PurchaseOutcome> buy(StoreProductKind kind) async {
    final details = _details[kind];
    if (!_storeAvailable || details == null) return PurchaseOutcome.unavailable;

    final completer = Completer<PurchaseOutcome>();
    _pending[kind.id] = completer;

    try {
      final param = PurchaseParam(productDetails: details);
      final started = kind.isConsumable
          // `autoConsume` الافتراضي يستهلك الشراء عند إتمامه، فيمكن شراؤه ثانية.
          ? await _store.buyConsumable(purchaseParam: param)
          : await _store.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _pending.remove(kind.id);
        return PurchaseOutcome.failed;
      }
    } catch (e) {
      debugPrint('تعذّر بدء الشراء: $e');
      _pending.remove(kind.id);
      return PurchaseOutcome.failed;
    }

    return completer.future;
  }

  @override
  Future<int> restore() async {
    if (!_storeAvailable) return 0;

    _restored = 0;
    try {
      await _store.restorePurchases();
      // المشتريات تصل عبر المجرى بعد لحظة، لا من ردّ الاستدعاء.
      await Future<void>.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('تعذّرت الاستعادة: $e');
    }
    return _restored;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final kind = StoreProductKind.fromId(purchase.productID);

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _finish(purchase.productID, PurchaseOutcome.pending);
        case PurchaseStatus.purchased:
          if (kind != null) await _deliver(kind);
          _finish(purchase.productID, PurchaseOutcome.purchased);
        case PurchaseStatus.restored:
          // المستهلَكات لا تُستعاد: من اشترى قلوباً واستهلكها لا يأخذها ثانية
          // عند كل إقلاع. غير المستهلَك وحده يُعاد تفعيله.
          if (kind != null && !kind.isConsumable) {
            _restored++;
            await _deliver(kind);
          }
          _finish(purchase.productID, PurchaseOutcome.purchased);
        case PurchaseStatus.canceled:
          _finish(purchase.productID, PurchaseOutcome.cancelled);
        case PurchaseStatus.error:
          debugPrint('فشل الشراء: ${purchase.error?.message}');
          _finish(purchase.productID, PurchaseOutcome.failed);
      }

      // إقرار الشراء خلال ثلاثة أيام شرط من غوغل، وإلا استُرجع المبلغ تلقائياً.
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (e) {
          debugPrint('تعذّر إقرار الشراء: $e');
        }
      }
    }
  }

  Future<void> _deliver(StoreProductKind kind) async {
    if (kind == StoreProductKind.removeAds && !_adsRemoved) {
      _adsRemoved = true;
      await _entitlements.writeAdsRemoved(true);
    }
    _onDelivered?.call(kind);
    _notify();
  }

  /// ردّ [buy] ينتهي مرة واحدة؛ المجرى قد يعيد الحدث نفسه.
  void _finish(String productId, PurchaseOutcome outcome) {
    final completer = _pending.remove(productId);
    if (completer != null && !completer.isCompleted) completer.complete(outcome);
  }

  void _notify() => _onChanged?.call();

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
