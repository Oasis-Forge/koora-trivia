import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/repositories/billing_service.dart';

/// يغلّف [BillingService] ويوصل ما اشتراه اللاعب إلى بقية التطبيق.
///
/// التسليم يمرّ من هنا لا من شاشة المتجر: الشراء قد يكتمل والتطبيق مغلق (دفع
/// معلّق، أو شراء على جهاز آخر)، فيصل عند الإقلاع التالي بلا شاشة مفتوحة.
class PurchasesProvider extends ChangeNotifier {
  PurchasesProvider({
    required BillingService service,
    required Future<void> Function(int coins) grantCoins,
    required void Function() onAdsRemoved,
  })  : _service = service,
        _grantCoins = grantCoins,
        _onAdsRemoved = onAdsRemoved {
    _service.onChanged = notifyListeners;
    _service.onDelivered = _deliver;
  }

  final BillingService _service;
  final Future<void> Function(int coins) _grantCoins;
  final void Function() _onAdsRemoved;

  StoreProductKind? _busy;

  /// المنتج الذي تُعرض نافذة شرائه الآن، أو `null`.
  StoreProductKind? get busy => _busy;

  bool get isAvailable => _service.isAvailable;
  List<StoreProduct> get products => _service.products;
  bool get adsRemoved => _service.adsRemoved;

  Future<void> init() async {
    await _service.init();
    // استحقاق محفوظ من تشغيل سابق يوقف الإعلانات فوراً.
    if (_service.adsRemoved) _onAdsRemoved();
    notifyListeners();
  }

  Future<PurchaseOutcome> buy(StoreProductKind kind) async {
    if (_busy != null) return PurchaseOutcome.failed;

    _busy = kind;
    notifyListeners();
    try {
      return await _service.buy(kind);
    } finally {
      _busy = null;
      notifyListeners();
    }
  }

  /// محاولة جديدة إن لم يردّ المتجر عند الإقلاع — عند العودة إلى التطبيق وفتح المتجر.
  Future<void> refresh() => _service.refresh();

  /// يعيد عدد ما استُعيد؛ صفر يعني لا مشتريات سابقة على هذا الحساب.
  Future<int> restore() => _service.restore();

  void _deliver(StoreProductKind kind, {required bool alreadyDelivered}) {
    switch (kind) {
      case StoreProductKind.coinsSmall:
        _grantCoins(AppConfig.coinsPerSmallPack);
      case StoreProductKind.removeAds:
        _onAdsRemoved();
      case StoreProductKind.removeAdsBundle:
        _onAdsRemoved();
        // عملات الباقة مرة واحدة: إعادة التفعيل تعيد إزالة الإعلانات وحدها.
        if (!alreadyDelivered) _grantCoins(AppConfig.coinsInRemoveAdsBundle);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _service.onChanged = null;
    _service.onDelivered = null;
    _service.dispose();
    super.dispose();
  }
}
