import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/widgets/hearts_bar.dart';
import 'package:provider/provider.dart';

class _FakeRepo implements EconomyRepository {
  _FakeRepo(this.economy);

  Economy economy;
  int saves = 0;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async {
    economy = value;
    saves++;
  }
}

final _t0 = DateTime(2026, 9, 13, 10);

/// رصيد ناقص آخر تجديد له عند [_t0].
Economy _missing(int hearts) =>
    Economy(hearts: hearts, lastRegenAtIso: _t0.toIso8601String());

class _Harness {
  late DateTime now;
  late _FakeRepo repo;
  late EconomyProvider provider;
  int notified = 0;

  Future<void> start(Economy economy, {Duration after = Duration.zero}) async {
    now = _t0.add(after);
    repo = _FakeRepo(economy);
    provider = EconomyProvider(repository: repo, clock: () => now);
    await provider.init();
    provider.addListener(() => notified++);
  }
}

void main() {
  group('EconomyProvider.refresh', () {
    test('مرور دقيقة يحرّك العدّاد ويُخطر الواجهة دون حفظ', () async {
      final h = _Harness();
      await h.start(_missing(3), after: const Duration(minutes: 1));
      expect(h.provider.untilNextHeart, const Duration(minutes: 29));

      h.now = _t0.add(const Duration(minutes: 2));
      h.provider.refresh();

      expect(h.provider.untilNextHeart, const Duration(minutes: 28));
      expect(h.notified, 1);
      expect(h.repo.saves, 0);
    });

    test('ثوانٍ لا تغيّر الدقيقة المعروضة لا تُخطر', () async {
      final h = _Harness();
      await h.start(
        _missing(3),
        after: const Duration(minutes: 1, seconds: 10),
      );

      h.now = _t0.add(const Duration(minutes: 1, seconds: 30));
      h.provider.refresh();

      expect(h.notified, 0);
    });

    test('قلب يتجدّد والشاشة مفتوحة: يزيد الرصيد ويُحفظ', () async {
      final h = _Harness();
      await h.start(_missing(2), after: const Duration(minutes: 5));

      h.now = _t0.add(const Duration(minutes: 31));
      h.provider.refresh();

      expect(h.provider.hearts, 3);
      expect(h.provider.untilNextHeart, const Duration(minutes: 29));
      expect(h.repo.saves, 1);
      expect(h.notified, 1);
    });
  });

  group('عدّاد القلب التالي بعد تغيّر الرصيد', () {
    test('قلب ممنوح لا يعيد الانتظار إلى نصف ساعة كاملة', () async {
      final h = _Harness();
      await h.start(_missing(2), after: const Duration(minutes: 10));

      await h.provider.grantDailyChallengeHeart();

      expect(h.provider.hearts, 3);
      expect(h.provider.untilNextHeart, const Duration(minutes: 20));
    });

    test('قلب ممنوح يملأ الرصيد: لا عدّاد', () async {
      final h = _Harness();
      await h.start(_missing(4), after: const Duration(minutes: 10));

      await h.provider.grantDailyChallengeHeart();

      expect(h.provider.hearts, AppConfig.maxHearts);
      expect(h.provider.untilNextHeart, isNull);
    });

    test('خسارة أول قلب تُظهر العدّاد فوراً من لحظة الخسارة', () async {
      final h = _Harness();
      await h.start(const Economy(), after: const Duration(minutes: 3));
      expect(h.provider.untilNextHeart, isNull);

      await h.provider.consumeHeart();

      expect(
        h.provider.untilNextHeart,
        const Duration(minutes: AppConfig.heartRegenMinutes),
      );
      expect(h.provider.raw.lastRegenAtIso, h.now.toIso8601String());
    });
  });

  testWidgets('شريط القلوب يحدّث عدّاده وحده كل نصف دقيقة', (tester) async {
    final h = _Harness();
    await h.start(_missing(3), after: const Duration(minutes: 1));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: h.provider,
        child: const MaterialApp(home: Scaffold(body: HeartsBar())),
      ),
    );
    expect(find.text('29 د'), findsOneWidget);

    h.now = _t0.add(const Duration(minutes: 3));
    await tester.pump(
      const Duration(seconds: AppConfig.heartsRefreshSeconds),
    );

    expect(find.text('27 د'), findsOneWidget);
  });

  testWidgets('والقلوب ممتلئة لا يحفظ الشريط ولا يُخطر كل نصف دقيقة',
      (tester) async {
    final h = _Harness();
    await h.start(const Economy());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: h.provider,
        child: const MaterialApp(home: Scaffold(body: HeartsBar())),
      ),
    );

    h.now = _t0.add(const Duration(minutes: 5));
    await tester.pump(
      const Duration(seconds: AppConfig.heartsRefreshSeconds * 2),
    );

    expect(h.repo.saves, 0);
    expect(h.notified, 0);
  });
}
