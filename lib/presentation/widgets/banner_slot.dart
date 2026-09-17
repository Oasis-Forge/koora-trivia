import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/ads_provider.dart';

/// شريط إعلاني مثبّت أسفل الشاشة، يوضع في `Scaffold.bottomNavigationBar`.
///
/// **المكان محجوز قبل وصول الإعلان.** لو ظهر الشريط فجأة بعد اكتمال التحميل
/// لانزاح ما فوقه بمقدار ارتفاعه، فينقر اللاعب على الإعلان بدل الزر الذي كان
/// تحت إصبعه — وهي «نقرة غير صالحة» عند AdMob تُعرّض الحساب للإيقاف.
///
/// ولنفس السبب المقاس ثابت (`AdSize.banner`) لا متكيّف: الارتفاع معروف قبل
/// الطلب، فلا يتغيّر الحجز بين جهاز وآخر ولا بعد وصول الإعلان.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});

  /// منفذ للاختبارات فقط: يستبدل إعلان AdMob الحقيقي بودجة بسيطة، فاختبارات
  /// الودجات بلا منصة تحمّل إعلاناً. الشاشات تبني `const BannerSlot()` فلا
  /// مجال لتمريره في المُنشئ.
  @visibleForTesting
  static Widget Function(String unitId)? testAdBuilder;

  /// ارتفاع `AdSize.banner` القياسي.
  static const double adHeight = 50;

  /// فراغ يفصل الإعلان عمّا فوقه، فلا يلامس زراً قابلاً للنقر.
  static const double gap = 8;

  static const double totalHeight = adHeight + gap;

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // `watch` هنا يعيد الاستدعاء حين تصل الموافقة أو تُهيَّأ الحزمة بعد الإقلاع،
    // فيبدأ التحميل حينها بدل أن يبقى الشريط فارغاً حتى الشاشة التالية.
    final ads = context.watch<AdsProvider>();
    if (ads.areBannersAllowed) _load(ads.bannerUnitId);
  }

  void _load(String unitId) {
    if (_ad != null || _loaded) return;

    if (BannerSlot.testAdBuilder != null) {
      _loaded = true;
      return;
    }

    final ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
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

    final ad = _ad;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: BannerSlot.totalHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: BannerSlot.adHeight,
            child: BannerSlot.testAdBuilder?.call(ads.bannerUnitId) ??
                (_loaded && ad != null ? AdWidget(ad: ad) : null),
          ),
        ),
      ),
    );
  }
}
