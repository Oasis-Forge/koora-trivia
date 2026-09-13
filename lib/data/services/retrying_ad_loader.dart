import 'dart:async';
import 'dart:math' as math;

/// طلب تحميل إعلان: يستدعي [onLoaded] بالإعلان أو [onFailed] برسالة الخطأ.
typedef AdLoadRequest<T> = void Function(
  void Function(T ad) onLoaded,
  void Function(String message) onFailed,
);

/// يحتفظ بإعلان واحد جاهز، ويعيد المحاولة بعد الفشل بمهلة متصاعدة.
///
/// منطق بحت بلا SDK حتى يُختبر بمؤقّتات مزيّفة؛ `AdMobAdService` يمرّر له
/// استدعاء التحميل الحقيقي. قبله كان الفشل الأول نهائياً حتى إعادة التشغيل.
class RetryingAdLoader<T> {
  RetryingAdLoader({
    required AdLoadRequest<T> request,
    required List<Duration> retryDelays,
    void Function()? onChanged,
    void Function(T ad)? disposeAd,
  })  : assert(retryDelays.isNotEmpty),
        _request = request,
        _retryDelays = retryDelays,
        _onChanged = onChanged,
        _disposeAd = disposeAd;

  final AdLoadRequest<T> _request;
  final List<Duration> _retryDelays;
  final void Function()? _onChanged;
  final void Function(T ad)? _disposeAd;

  T? _ad;
  bool _loading = false;
  Timer? _retryTimer;
  int _failures = 0;

  /// يُبطل ردود نداء تحميلٍ بدأ قبل [stop]، فلا يعود إعلان بعد سحب الموافقة.
  int _generation = 0;

  bool get isReady => _ad != null;
  bool get isLoading => _loading;
  bool get hasPendingRetry => _retryTimer?.isActive ?? false;

  /// يبدأ التحميل إن لم يوجد إعلان جاهز أو تحميل جارٍ.
  void load() {
    if (_ad != null || _loading) return;

    _retryTimer?.cancel();
    _retryTimer = null;
    _loading = true;
    final generation = _generation;

    try {
      _request(
        (ad) {
          if (generation != _generation) {
            _disposeAd?.call(ad);
            return;
          }
          _loading = false;
          _failures = 0;
          _ad = ad;
          _onChanged?.call();
        },
        (_) {
          if (generation != _generation) return;
          _loading = false;
          _scheduleRetry();
        },
      );
    } catch (_) {
      // خطأ متزامن من SDK يُعامَل كفشل تحميل، وإلا بقي `_loading` عالقاً للأبد.
      if (generation != _generation) return;
      _loading = false;
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    // المهلة تتصاعد مع كل فشل متتالٍ حتى لا نُغرق الشبكة أثناء انقطاع طويل.
    final delay = _retryDelays[math.min(_failures, _retryDelays.length - 1)];
    _failures++;
    _retryTimer = Timer(delay, load);
  }

  /// يأخذ الإعلان الجاهز ليُعرض — الإعلان الواحد لا يُعرض مرتين.
  T? take() {
    final ad = _ad;
    if (ad == null) return null;
    _ad = null;
    _onChanged?.call();
    return ad;
  }

  /// محاولة فورية دون انتظار المهلة — عند العودة إلى التطبيق مثلاً، حين يكون
  /// الاتصال قد عاد. تبدأ المهل من أولها لأن الظروف تغيّرت.
  void retryNow() {
    if (_ad != null || _loading) return;
    _failures = 0;
    load();
  }

  /// إيقاف كامل: يلغي المحاولة المعلّقة ويتخلّص من الإعلان الجاهز.
  void stop() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _loading = false;
    _failures = 0;

    final ad = _ad;
    if (ad == null) return;
    _ad = null;
    _disposeAd?.call(ad);
    _onChanged?.call();
  }
}
