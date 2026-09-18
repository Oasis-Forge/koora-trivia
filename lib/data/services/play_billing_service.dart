import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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
  /// [store] و[consume] منفذان للاختبارات؛ غيابهما يعني Play الحقيقي.
  PlayBillingService({
    required EntitlementLocalDataSource entitlements,
    InAppPurchase? store,
    Future<void> Function(PurchaseDetails purchase)? consume,
  })  : _entitlements = entitlements,
        _store = store ?? InAppPurchase.instance,
        _consumeOverride = consume;

  final EntitlementLocalDataSource _entitlements;
  final InAppPurchase _store;
  final Future<void> Function(PurchaseDetails purchase)? _consumeOverride;

  final Map<StoreProductKind, ProductDetails> _details = {};
  final Map<String, Completer<PurchaseOutcome>> _pending = {};

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  void Function()? _onChanged;
  void Function(StoreProductKind kind, {required bool alreadyDelivered})?
      _onDelivered;
  bool _storeAvailable = false;
  bool _adsRemoved = false;
  int _restored = 0;

  @override
  set onChanged(void Function()? listener) => _onChanged = listener;

  @override
  set onDelivered(
    void Function(StoreProductKind kind, {required bool alreadyDelivered})?
        listener,
  ) =>
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
        case PurchaseStatus.restored:
          // «جديد» = لم يُقرّ بعد. نُقرّ كل شراء فور تسليمه، فالإقرار هو علامة
          // التسليم. حالة الإضافة وحدها لا تكفي: `in_app_purchase_android` يصف
          // بـ restored كل ما تعيده Play عند الإقلاع، ومنه شراء لم يصل حدثه قط
          // (أُغلق التطبيق أثناء نافذة الدفع، أو اكتمل دفع معلّق وهو مغلق). كان
          // يُعامل كاستعادة: تُزال الإعلانات بلا عملات الباقة، وحزمة العملات لا
          // تُسلَّم ولا تُستهلك فلا تُشترى ثانية (19 سبتمبر 2026).
          final isNew = purchase.pendingCompletePurchase;
          if (kind != null && (isNew || !kind.isConsumable)) {
            if (purchase.status == PurchaseStatus.restored &&
                !kind.isConsumable) {
              _restored++;
            }
            await _deliver(kind, alreadyDelivered: !isNew);
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

      // الاستهلاك التلقائي لا يلحق إلا بالشراء الحيّ في الجلسة نفسها. حزمة عملات
      // تعيدها الاستعادة ما زالت «مملوكة»، فتُستهلك هنا وإلا رفضت Play شراءها ثانية.
      if (kind != null &&
          kind.isConsumable &&
          purchase.status == PurchaseStatus.restored) {
        try {
          await (_consumeOverride ?? _consumeOnPlay)(purchase);
        } catch (e) {
          debugPrint('تعذّر استهلاك الشراء: $e');
        }
      }
    }
  }

  Future<void> _consumeOnPlay(PurchaseDetails purchase) async {
    final android = _store
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final result = await android.consumePurchase(purchase);
    if (result.responseCode != BillingResponse.ok) {
      debugPrint('رفضت Play استهلاك الشراء: ${result.debugMessage}');
    }
  }

  Future<void> _deliver(
    StoreProductKind kind, {
    required bool alreadyDelivered,
  }) async {
    if (kind.removesAds && !_adsRemoved) {
      _adsRemoved = true;
      await _entitlements.writeAdsRemoved(true);
    }
    _onDelivered?.call(kind, alreadyDelivered: alreadyDelivered);
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
