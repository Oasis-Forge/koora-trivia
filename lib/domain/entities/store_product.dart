/// ما يُباع بالمال الحقيقي داخل التطبيق.
///
/// المعرّفات هي نفسها المكتوبة في Play Console حرفاً بحرف؛ تغييرها بعد أول
/// عملية شراء يعني أن المشتريات القديمة لا تُستعاد.
enum StoreProductKind {
  /// مستهلَكة: تُشترى مراراً. ترتيب القيم هنا هو ترتيب العرض في المتجر.
  heartsSmall('hearts_small'),
  heartsLarge('hearts_large'),

  /// غير مستهلَك: يُشترى مرة ويُستعاد على أي جهاز بحساب اللاعب نفسه.
  removeAds('remove_ads');

  const StoreProductKind(this.id);

  /// معرّف المنتج في Play Console.
  final String id;

  bool get isConsumable => this != StoreProductKind.removeAds;

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
