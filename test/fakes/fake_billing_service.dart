import 'package:football_trivia/domain/entities/store_product.dart';
import 'package:football_trivia/domain/repositories/billing_service.dart';

/// متجر مزيّف مشترك بين الاختبارات — بلا Play ولا منصة.
class FakeBillingService implements BillingService {
  FakeBillingService({
    this.available = true,
    this.outcome = PurchaseOutcome.purchased,
    this.adsRemovedValue = false,
    this.restoredAtInit = const [],
  });

  /// هل ردّ المتجر بمنتجاته؟ `false` يحاكي ملف دفع تحت التحقق.
  bool available;
  PurchaseOutcome outcome;
  bool adsRemovedValue;

  /// مشتريات سابقة تصل عند التهيئة، كما تفعل Play على جهاز جديد.
  final List<StoreProductKind> restoredAtInit;

  void Function()? listener;
  void Function(StoreProductKind kind)? delivered;
  final List<StoreProductKind> bought = [];
  int restoreCalls = 0;
  bool disposed = false;

  @override
  set onChanged(void Function()? value) => listener = value;

  @override
  set onDelivered(void Function(StoreProductKind kind)? value) =>
      delivered = value;

  @override
  bool get isAvailable => available;

  @override
  bool get adsRemoved => adsRemovedValue;

  @override
  List<StoreProduct> get products => available
      ? [
          for (final kind in StoreProductKind.values)
            StoreProduct(kind: kind, title: kind.id, price: '\$1.99'),
        ]
      : const [];

  @override
  Future<void> init() async {
    for (final kind in restoredAtInit) {
      if (kind == StoreProductKind.removeAds) adsRemovedValue = true;
      delivered?.call(kind);
    }
    listener?.call();
  }

  @override
  Future<PurchaseOutcome> buy(StoreProductKind kind) async {
    if (!available) return PurchaseOutcome.unavailable;

    bought.add(kind);
    if (outcome == PurchaseOutcome.purchased) {
      if (kind == StoreProductKind.removeAds) adsRemovedValue = true;
      delivered?.call(kind);
    }
    return outcome;
  }

  @override
  Future<int> restore() async {
    restoreCalls++;
    if (!adsRemovedValue) return 0;

    delivered?.call(StoreProductKind.removeAds);
    return 1;
  }

  @override
  void dispose() => disposed = true;
}
