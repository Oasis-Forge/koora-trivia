import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/ads_provider.dart';
import '../providers/purchases_provider.dart';
import '../screens/shop_screen.dart';

/// شريط إعلاني بعرض الشاشة، مثبّت أسفلها، يوضع في `Scaffold.bottomNavigationBar`.
///
/// **المكان محجوز قبل وصول الإعلان.** لو ظهر الشريط فجأة بعد اكتمال التحميل
/// لانزاح ما فوقه بمقدار ارتفاعه، فينقر اللاعب على الإعلان بدل الزر الذي كان
/// تحت إصبعه — وهي «نقرة غير صالحة» عند AdMob تُعرّض الحساب للإيقاف.
///
/// المقاس «متكيّف مثبّت»: بعرض الشاشة كاملاً (طلب المالك، 18 سبتمبر 2026)،
/// وارتفاعه يُسأل عنه قبل طلب الإعلان فيُحجز مسبقاً كما كان المقاس الثابت.
/// يُحسب مرة ويُشارك بين الشاشات، فلا تنتظره كل شاشة من جديد.
class BannerSlot extends StatefulWidget {
  const BannerSlot({
    super.key,
    this.removeAdsLink = true,
    this.maxHeightFraction,
  });

  /// رابط صغير «إزالة الإعلانات» فوق الشريط يفتح المتجر.
  ///
  /// مطفأ في شاشة السؤال (الضغط عليه يترك الجولة، وهو زر آخر قرب الخيارات)
  /// وفي المتجر نفسه.
  final bool removeAdsLink;

  /// أقصى ارتفاع للإعلان كنسبة من ارتفاع الشاشة؛ إن تجاوزه المقاس المتكيّف
  /// نعود إلى المقاس الثابت 320×50 في هذه الشاشة وحدها.
  ///
  /// شاشة السؤال تحدّه (`AppConfig.quizBannerMaxHeightFraction`): غوغل تسمح حتى
  /// 15%، وهذا على هاتف 640 يدفع الخيار الرابع تحت الحافة والوقت يجري.
  final double? maxHeightFraction;

  /// منفذ للاختبارات فقط: يستبدل إعلان AdMob الحقيقي بودجة بسيطة، فاختبارات
  /// الودجات بلا منصة تحمّل إعلاناً. الشاشات تبني `const BannerSlot()` فلا
  /// مجال لتمريره في المُنشئ.
  @visibleForTesting
  static Widget Function(String unitId)? testAdBuilder;

  /// منفذ للاختبارات: ارتفاع الإعلان المتكيّف، فالمنصة التي تحسبه غائبة.
  /// غوغل تسمح حتى 15% من ارتفاع الشاشة، فتختبر الشاشات الضيقة أسوأ حالة.
  @visibleForTesting
  static double? testAdHeight;

  /// ارتفاع الحجز قبل معرفة المقاس المتكيّف — وهو أيضاً أدنى ارتفاع له.
  static const double adHeight = 50;

  /// فراغ يفصل الإعلان عمّا فوقه، فلا يلامس زراً قابلاً للنقر.
  static const double gap = 8;

  /// ارتفاع سطر «إزالة الإعلانات».
  static const double linkHeight = 32;

  static const double totalHeight = adHeight + gap;

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  /// المقاس المتكيّف لعرض الشاشة، مشترك بين كل الشرائط.
  static AdSize? _sharedSize;
  static int? _sharedWidth;

  BannerAd? _ad;
  bool _loaded = false;
  bool _sizing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // `watch` هنا يعيد الاستدعاء حين تصل الموافقة أو تُهيَّأ الحزمة بعد الإقلاع،
    // فيبدأ التحميل حينها بدل أن يبقى الشريط فارغاً حتى الشاشة التالية.
    final ads = context.watch<AdsProvider>();
    if (!ads.areBannersAllowed) return;

    if (BannerSlot.testAdBuilder != null) {
      _loaded = true;
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_sharedSize != null && _sharedWidth == width) {
      _load(ads.bannerUnitId, _fitted(_sharedSize!));
    } else {
      _resolveSize(ads.bannerUnitId, width);
    }
  }

  /// المقاس المتكيّف إن اتسع له الحدّ، وإلا المقاس الثابت.
  AdSize _fitted(AdSize adaptive) =>
      _fits(adaptive.height.toDouble()) ? adaptive : AdSize.banner;

  bool _fits(double height) {
    final fraction = widget.maxHeightFraction;
    return fraction == null ||
        height <= fraction * MediaQuery.sizeOf(context).height;
  }

  Future<void> _resolveSize(String unitId, int width) async {
    if (_sizing) return;
    _sizing = true;

    // المتكيّف العادي لا «الكبير» الذي توصي به الحزمة: الكبير 128 على هاتف
    // عرضه 411 (14% من الشاشة) مقابل 64 للعادي — قيس على المحاكي، 18 سبتمبر 2026.
    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    _sizing = false;
    if (!mounted) return;

    // لا مقاس متكيّف (نادر) — نعود إلى المقاس الثابت بدل ألا نعرض شيئاً.
    _sharedSize = size ?? AdSize.banner;
    _sharedWidth = width;
    setState(() {});
    _load(unitId, _fitted(_sharedSize!));
  }

  void _load(String unitId, AdSize size) {
    if (_ad != null || _loaded) return;

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        // فشل التحميل شائع مع انقطاع الاتصال: نتخلص من الإعلان ونترك المكان
        // فارغاً. المحاولة التالية تأتي مع بناء الشاشة التالية.
        onAdFailedToLoad: (ad, error) {
          debugPrint('تعذّر تحميل الشريط الإعلاني: ${error.message}');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsProvider>();
    if (!ads.areBannersAllowed) return const SizedBox.shrink();

    // الرابط لا يظهر إلا حين يمكن الشراء فعلاً؛ قبل ذلك يقود إلى «قريباً».
    final showLink = widget.removeAdsLink &&
        context.watch<PurchasesProvider>().isAvailable;
    final natural = BannerSlot.testAdHeight ?? _sharedSize?.height.toDouble();
    final adHeight = natural == null
        ? BannerSlot.adHeight
        : _fits(natural)
            ? natural
            : AdSize.banner.height.toDouble();
    final ad = _ad;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLink) const _RemoveAdsLink(),
          const SizedBox(height: BannerSlot.gap),
          SizedBox(
            width: double.infinity,
            height: adHeight,
            child: Center(
              child: BannerSlot.testAdBuilder?.call(ads.bannerUnitId) ??
                  (_loaded && ad != null
                      ? SizedBox(
                          width: ad.size.width.toDouble(),
                          height: ad.size.height.toDouble(),
                          child: AdWidget(ad: ad),
                        )
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// «إزالة الإعلانات» — نص صغير فوق الشريط يفتح المتجر.
///
/// منفصل عن الإعلان بفراغ [BannerSlot.gap] وبشكل لا يشبهه، فلا يُحسب النقر
/// عليه نقراً على الإعلان ولا يُظنّ جزءاً منه.
class _RemoveAdsLink extends StatelessWidget {
  const _RemoveAdsLink();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BannerSlot.linkHeight,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(ShopScreen.routeName),
          icon: Icon(Icons.block_rounded, size: 14, color: AppColors.chalkMuted),
          label: Text(
            AppStrings.removeAds,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.chalkMuted,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            minimumSize: const Size(0, BannerSlot.linkHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
