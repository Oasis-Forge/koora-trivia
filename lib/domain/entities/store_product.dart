/// ما يُباع بالمال الحقيقي داخل التطبيق.
///
/// المعرّفات هي نفسها المكتوبة في Play Console حرفاً بحرف؛ تغييرها بعد أول
/// عملية شراء يعني أن المشتريات القديمة لا تُستعاد.
enum StoreProductKind {
  /// حزمة عملات مستهلَكة: تُشترى مراراً. ترتيب القيم هنا هو ترتيب العرض.
  ///
  /// نبيع عملات لا قلوباً (قرار المالك، 18 سبتمبر 2026): القلوب تبقى تحت سقفها،
  /// والعملات تشتري ملء القلوب أو المساعدات من المتجر نفسه.
  coinsSmall('coins_small'),

  /// غير مستهلَك: يُشترى مرة ويُستعاد على أي جهاز بحساب اللاعب نفسه.
  removeAds('remove_ads'),

  /// باقة غير مستهلَكة: إزالة الإعلانات ومعها عملات، تُشترى مرة واحدة.
  ///
  /// عند الاستعادة (جهاز جديد أو إعادة تثبيت) تعود إزالة الإعلانات وحدها؛
  /// العملات تُمنح عند الشراء الأصلي فقط، وإلا صار مسح البيانات ثم الاستعادة
  /// طريقاً لعملات مجانية بلا حد.
  removeAdsBundle('remove_ads_bundle');

  /// هل يوقف الإعلانات؟ الإزالة المستقلة والباقة سواء.
  bool get removesAds =>
      this == StoreProductKind.removeAds ||
      this == StoreProductKind.removeAdsBundle;

  const StoreProductKind(this.id);

  /// معرّف المنتج في Play Console.
  final String id;

  bool get isConsumable => this == StoreProductKind.coinsSmall;

  static StoreProductKind? fromId(String id) {
    for (final kind in StoreProductKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// منتج كما وصفه المتجر: السعر نص جاهز بعملة اللاعب، لا رقم نحسبه نحن.
class StoreProduct {
  const StoreProduct({
    required this.kind,
    required this.title,
    required this.price,
  });

  final StoreProductKind kind;
  final String title;

  /// السعر منسّقاً بعملة البلد كما أرسله المتجر («٤٫٩٩ ر.س» مثلاً).
  final String price;
}

/// نتيجة محاولة شراء.
enum PurchaseOutcome {
  /// اكتمل الشراء وسُلّم ما يقابله.
  purchased,

  /// بانتظار إتمام الدفع (تحويل بنكي أو موافقة ولي أمر) — لا يُسلَّم شيء بعد.
  pending,

  /// أغلق اللاعب نافذة الشراء.
  cancelled,

  /// خطأ من المتجر أو الشبكة.
  failed,

  /// المتجر غير متاح أو المنتج غير معروف — لا يُعرض المنتج أصلاً في هذه الحالة.
  unavailable,
}
