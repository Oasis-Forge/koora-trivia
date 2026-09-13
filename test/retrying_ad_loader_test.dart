import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/services/retrying_ad_loader.dart';

/// طلب تحميل مزيّف: يحتفظ بردود النداء ليقرر الاختبار متى ينجح أو يفشل.
class _FakeRequest {
  final _pairs = <({
    void Function(String ad) onLoaded,
    void Function(String message) onFailed,
  })>[];

  int get calls => _pairs.length;

  void call(
    void Function(String ad) onLoaded,
    void Function(String message) onFailed,
  ) =>
      _pairs.add((onLoaded: onLoaded, onFailed: onFailed));

  /// [at] يختار طلباً سابقاً بعينه؛ الافتراضي آخر طلب.
  void succeed([String ad = 'ad', int? at]) =>
      _pairs[at ?? _pairs.length - 1].onLoaded(ad);

  void fail([int? at]) => _pairs[at ?? _pairs.length - 1].onFailed('no fill');
}

const _delays = [
  Duration(seconds: 10),
  Duration(seconds: 20),
  Duration(seconds: 40),
];

class _Harness {
  _Harness() {
    loader = RetryingAdLoader<String>(
      request: request.call,
      retryDelays: _delays,
      onChanged: () => changes++,
      disposeAd: disposed.add,
    );
  }

  final request = _FakeRequest();
  final disposed = <String>[];
  int changes = 0;
  late final RetryingAdLoader<String> loader;
}

void main() {
  test('التحميل الناجح يجعل الإعلان جاهزاً ويُخطر المستمع', () {
    final h = _Harness();

    h.loader.load();
    expect(h.request.calls, 1);
    expect(h.loader.isLoading, isTrue);
    expect(h.loader.isReady, isFalse);

    h.request.succeed();
    expect(h.loader.isReady, isTrue);
    expect(h.loader.isLoading, isFalse);
    expect(h.changes, 1);
  });

  test('لا طلب مكرّر أثناء تحميل جارٍ ولا مع إعلان جاهز', () {
    final h = _Harness();

    h.loader
      ..load()
      ..load();
    expect(h.request.calls, 1);

    h.request.succeed();
    h.loader
      ..load()
      ..retryNow();
    expect(h.request.calls, 1);
  });

  test('الفشل يعيد المحاولة بمهل متصاعدة ثم يثبت على آخرها', () {
    fakeAsync((async) {
      final h = _Harness();
      h.loader.load();

      for (final (i, delay) in [..._delays, _delays.last].indexed) {
        h.request.fail();
        expect(h.loader.hasPendingRetry, isTrue);

        async.elapse(delay - const Duration(seconds: 1));
        expect(h.request.calls, i + 1, reason: 'المحاولة ${i + 2} مبكرة');

        async.elapse(const Duration(seconds: 1));
        expect(h.request.calls, i + 2);
      }
    });
  });

  test('النجاح يعيد المهلة إلى أولها', () {
    fakeAsync((async) {
      final h = _Harness();
      h.loader.load();

      h.request.fail();
      async.elapse(_delays[0]);
      h.request.fail();
      async.elapse(_delays[1]);
      expect(h.request.calls, 3);

      h.request.succeed();
      h.loader
        ..take()
        ..load();
      expect(h.request.calls, 4);

      h.request.fail();
      async.elapse(_delays[0]);
      expect(h.request.calls, 5);
    });
  });

  test('take يسلّم الإعلان مرة واحدة ويُخطر المستمع', () {
    final h = _Harness();
    h.loader.load();
    h.request.succeed();

    expect(h.loader.take(), 'ad');
    expect(h.loader.isReady, isFalse);
    expect(h.loader.take(), isNull);
    expect(h.changes, 2);
  });

  test('retryNow لا ينتظر المهلة ويبدأ المهل من أولها', () {
    fakeAsync((async) {
      final h = _Harness();
      h.loader.load();

      h.request.fail();
      async.elapse(_delays[0]);
      h.request.fail();
      expect(h.request.calls, 2);

      // عاد اللاعب إلى التطبيق قبل انقضاء المهلة الثانية.
      h.loader.retryNow();
      expect(h.request.calls, 3);
      expect(h.loader.hasPendingRetry, isFalse);

      // المحاولة المعلّقة أُلغيت فلا طلب إضافي عند موعدها القديم.
      async.elapse(_delays[1]);
      expect(h.request.calls, 3);

      h.request.fail();
      async.elapse(_delays[0]);
      expect(h.request.calls, 4);
    });
  });

  test('stop يتخلّص من الإعلان الجاهز ويُخطر المستمع', () {
    final h = _Harness();
    h.loader.load();
    h.request.succeed();

    h.loader.stop();
    expect(h.loader.isReady, isFalse);
    expect(h.disposed, ['ad']);
    expect(h.changes, 2);
  });

  test('stop يلغي المحاولة المعلّقة', () {
    fakeAsync((async) {
      final h = _Harness();
      h.loader.load();
      h.request.fail();

      h.loader.stop();
      expect(h.loader.hasPendingRetry, isFalse);

      async.elapse(const Duration(minutes: 10));
      expect(h.request.calls, 1);
    });
  });

  test('إعلان يصل بعد stop يُتخلَّص منه ولا يصبح جاهزاً', () {
    fakeAsync((async) {
      final h = _Harness();
      h.loader.load();
      final lateRequest = h.request;

      h.loader.stop();
      lateRequest.succeed('late');
      expect(h.loader.isReady, isFalse);
      expect(h.disposed, ['late']);
      expect(h.changes, 0);

      // والفشل المتأخر لا يجدول محاولة.
      lateRequest.fail();
      expect(h.loader.hasPendingRetry, isFalse);
    });
  });

  test('خطأ متزامن من الطلب يُعامَل كفشل ولا يعلق التحميل', () {
    fakeAsync((async) {
      var calls = 0;
      final loader = RetryingAdLoader<String>(
        request: (_, __) {
          calls++;
          throw StateError('sdk');
        },
        retryDelays: _delays,
      );

      loader.load();
      expect(loader.isLoading, isFalse);
      expect(loader.hasPendingRetry, isTrue);

      async.elapse(_delays[0]);
      expect(calls, 2);
    });
  });

  test('ردّ طلبٍ قديم بعد stop ثم تحميل جديد لا يمسّ التحميل الجديد', () {
    fakeAsync((async) {
      final h = _Harness();
      h.loader.load();

      // سُحبت الموافقة ثم أُعيدت بسرعة، والطلب الأول ما زال معلّقاً في SDK.
      h.loader
        ..stop()
        ..load();
      expect(h.request.calls, 2);

      h.request.succeed('old', 0);
      expect(h.disposed, ['old']);
      expect(h.loader.isReady, isFalse);
      expect(h.loader.isLoading, isTrue, reason: 'الطلب الجديد ما زال جارياً');

      h.request.fail(0);
      expect(h.loader.hasPendingRetry, isFalse);
      expect(h.loader.isLoading, isTrue);

      h.request.succeed('new', 1);
      expect(h.loader.take(), 'new');
    });
  });
}
