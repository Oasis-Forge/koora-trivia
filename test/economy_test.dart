import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/data/datasources/economy_local_datasource.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/usecases/regenerate_hearts.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeEconomyRepository implements EconomyRepository {
  _FakeEconomyRepository([this.economy = const Economy()]);

  Economy economy;
  int saveCount = 0;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async {
    economy = value;
    saveCount++;
  }
}

void main() {
  const regen = RegenerateHearts();
  final now = DateTime(2026, 8, 4, 12, 0);

  String iso(Duration ago) => now.subtract(ago).toIso8601String();

  group('تجديد القلوب', () {
    test('الرصيد الممتلئ لا يتجاوز الحد الأقصى', () {
      final result = regen(
        Economy(hearts: AppConfig.maxHearts, lastRegenAtIso: iso(const Duration(hours: 10))),
        now: now,
      );

      expect(result.economy.hearts, AppConfig.maxHearts);
      expect(result.untilNextHeart, isNull);
    });

    test('نصف ساعة تمنح قلباً واحداً', () {
      final result = regen(
        Economy(hearts: 2, lastRegenAtIso: iso(const Duration(minutes: 30))),
        now: now,
      );

      expect(result.economy.hearts, 3);
    });

    test('ساعتان تمنحان أربعة قلوب', () {
      final result = regen(
        Economy(hearts: 1, lastRegenAtIso: iso(const Duration(hours: 2))),
        now: now,
      );

      expect(result.economy.hearts, 5);
    });

    test('التجديد لا يتجاوز الحد الأقصى مهما طال الوقت', () {
      final result = regen(
        Economy(hearts: 0, lastRegenAtIso: iso(const Duration(days: 3))),
        now: now,
      );

      expect(result.economy.hearts, AppConfig.maxHearts);
      expect(result.untilNextHeart, isNull);
    });

    test('أقل من نصف ساعة لا يمنح شيئاً ويعرض الوقت المتبقي', () {
      final result = regen(
        Economy(hearts: 2, lastRegenAtIso: iso(const Duration(minutes: 10))),
        now: now,
      );

      expect(result.economy.hearts, 2);
      expect(result.untilNextHeart, const Duration(minutes: 20));
    });

    test('البقية لا تضيع بين القراءات', () {
      // 50 دقيقة ⇒ قلب واحد + 20 دقيقة محفوظة نحو القلب التالي.
      final result = regen(
        Economy(hearts: 1, lastRegenAtIso: iso(const Duration(minutes: 50))),
        now: now,
      );

      expect(result.economy.hearts, 2);
      expect(result.untilNextHeart, const Duration(minutes: 10));
    });

    test('رجوع ساعة الجهاز للخلف لا ينتج رصيداً سالباً', () {
      final result = regen(
        Economy(
          hearts: 2,
          lastRegenAtIso: now.add(const Duration(days: 1)).toIso8601String(),
        ),
        now: now,
      );

      expect(result.economy.hearts, 2);
      expect(result.untilNextHeart, isNotNull);
    });

    test('تاريخ تالف لا يُسقط الحساب', () {
      final result = regen(
        const Economy(hearts: 3, lastRegenAtIso: 'ليس تاريخاً'),
        now: now,
      );

      expect(result.economy.hearts, 3);
    });

    test('الحدود اليومية تُصفَّر عند تغيّر اليوم', () {
      final result = regen(
        const Economy(
          hearts: 3,
          rewardedRefillsToday: 4,
          rewardedDayKey: '2026-08-03',
          hintsUsedToday: 3,
          hintsDayKey: '2026-08-03',
        ),
        now: now,
      );

      expect(result.economy.rewardedRefillsToday, 0);
      expect(result.economy.hintsUsedToday, 0);
      expect(result.economy.rewardedDayKey, DayKey.from(now));
    });

    test('الحدود اليومية تبقى ضمن اليوم نفسه', () {
      final result = regen(
        Economy(
          hearts: 3,
          rewardedRefillsToday: 2,
          rewardedDayKey: DayKey.from(now),
          hintsUsedToday: 1,
          hintsDayKey: DayKey.from(now),
        ),
        now: now,
      );

      expect(result.economy.rewardedRefillsToday, 2);
      expect(result.economy.hintsUsedToday, 1);
    });
  });

  group('EconomyProvider', () {
    test('البداية بقلوب ممتلئة', () async {
      final provider =
          EconomyProvider(repository: _FakeEconomyRepository());
      await provider.init();

      expect(provider.hearts, AppConfig.maxHearts);
      expect(provider.hasHearts, isTrue);
      expect(provider.isFull, isTrue);
    });

    test('الخصم ينقص قلباً ويحفظ', () async {
      final repo = _FakeEconomyRepository();
      final provider = EconomyProvider(repository: repo);
      await provider.init();

      final ok = await provider.consumeHeart();

      expect(ok, isTrue);
      expect(provider.hearts, AppConfig.maxHearts - 1);
      expect(repo.saveCount, greaterThan(0));
    });

    test('الخصم يفشل عند نفاد القلوب', () async {
      final repo = _FakeEconomyRepository(
        Economy(hearts: 0, lastRegenAtIso: DateTime.now().toIso8601String()),
      );
      final provider = EconomyProvider(repository: repo);
      await provider.init();

      expect(await provider.consumeHeart(), isFalse);
      expect(provider.hearts, 0);
      expect(provider.hasHearts, isFalse);
    });

    test('تحدي اليوم يمنح قلباً دون تجاوز الحد', () async {
      final repo = _FakeEconomyRepository(
        Economy(hearts: 2, lastRegenAtIso: DateTime.now().toIso8601String()),
      );
      final provider = EconomyProvider(repository: repo);
      await provider.init();

      expect(
        await provider.grantDailyChallengeHeart(dayKey: '2026-09-14'),
        isTrue,
      );
      expect(provider.hearts, 3);
    });

    test('قلب تحدي اليوم مرة واحدة ليومه، ويُمنح ليوم جديد', () async {
      final provider = EconomyProvider(
        repository: _FakeEconomyRepository(
          Economy(hearts: 2, lastRegenAtIso: DateTime.now().toIso8601String()),
        ),
      );
      await provider.init();

      expect(
        await provider.grantDailyChallengeHeart(dayKey: '2026-09-14'),
        isTrue,
      );
      expect(
        await provider.grantDailyChallengeHeart(dayKey: '2026-09-14'),
        isFalse,
      );
      expect(provider.hearts, 3);

      expect(
        await provider.grantDailyChallengeHeart(dayKey: '2026-09-15'),
        isTrue,
      );
      expect(provider.hearts, 4);
    });

    test('المنح لا يتجاوز الحد الأقصى ولا يُعدّ قلباً مضافاً', () async {
      final provider =
          EconomyProvider(repository: _FakeEconomyRepository());
      await provider.init();

      expect(
        await provider.grantDailyChallengeHeart(dayKey: '2026-09-14'),
        isFalse,
      );
      expect(provider.hearts, AppConfig.maxHearts);
    });

    test('يوم آخر قلب تحدٍّ يُحفظ ويُقرأ', () async {
      SharedPreferences.setMockInitialValues({});
      final source = PrefsEconomyDataSource();
      await source.write(const Economy(dailyHeartDayKey: '2026-09-14'));
      expect((await source.read()).dailyHeartDayKey, '2026-09-14');
    });

    test('الإعلان المكافأ يمنح قلباً ويستهلك من الحد اليومي', () async {
      final repo = _FakeEconomyRepository(
        Economy(hearts: 1, lastRegenAtIso: DateTime.now().toIso8601String()),
      );
      final provider = EconomyProvider(repository: repo);
      await provider.init();

      final before = provider.rewardedRefillsLeft;
      final ok = await provider.grantRewardedHearts();

      expect(ok, isTrue);
      expect(provider.hearts, 1 + AppConfig.heartsPerRewardedAdWatch);
      expect(provider.rewardedRefillsLeft, before - 1);
    });

    test('الإعلان المكافأ يُرفض بعد استنفاد الحد اليومي', () async {
      final repo = _FakeEconomyRepository(
        Economy(
          hearts: 1,
          lastRegenAtIso: DateTime.now().toIso8601String(),
          rewardedRefillsToday: AppConfig.maxRewardedRefillsPerDay,
          rewardedDayKey: DayKey.today(),
        ),
      );
      final provider = EconomyProvider(repository: repo);
      await provider.init();

      expect(provider.canWatchRewarded, isFalse);
      expect(await provider.grantRewardedHearts(), isFalse);
      expect(provider.hearts, 1);
    });

    test('المساعدات تنقص حتى النفاد', () async {
      final provider =
          EconomyProvider(repository: _FakeEconomyRepository());
      await provider.init();

      expect(provider.hintsLeft, AppConfig.freeHintsPerDay);

      for (var i = 0; i < AppConfig.freeHintsPerDay; i++) {
        expect(await provider.consumeHint(), isTrue);
      }

      expect(provider.hintsLeft, 0);
      expect(provider.hasHints, isFalse);
      expect(await provider.consumeHint(), isFalse);
    });
  });
}
