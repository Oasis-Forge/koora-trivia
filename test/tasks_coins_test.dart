import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/domain/entities/daily_task.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/usecases/regenerate_hearts.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';

class _FakeRepo implements EconomyRepository {
  _FakeRepo([this.economy = const Economy()]);

  Economy economy;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async => economy = value;
}

Future<EconomyProvider> _provider([Economy? seed]) async {
  final p = EconomyProvider(repository: _FakeRepo(seed ?? const Economy()));
  await p.init();
  return p;
}

void main() {
  group('المهام اليومية', () {
    test('تبدأ فارغة وغير قابلة للاستلام', () async {
      final p = await _provider();

      expect(p.tasks.length, 3);
      expect(p.tasks.every((t) => !t.isClaimable), isTrue);
      expect(p.claimableCount, 0);
      expect(p.coins, 0);
    });

    test('مهمة الإجابات تكتمل عند بلوغ الهدف', () async {
      final p = await _provider();

      for (var i = 0; i < AppConfig.taskAnswersTarget; i++) {
        await p.recordCorrectAnswer();
      }

      final task =
          p.tasks.firstWhere((t) => t.kind == TaskKind.correctAnswers);
      expect(task.progress, AppConfig.taskAnswersTarget);
      expect(task.isClaimable, isTrue);
      expect(p.claimableCount, 1);
    });

    test('العدد المعروض لا يتجاوز الهدف بعد الاستلام («21 / 10»)', () async {
      final p = await _provider();
      final answers = AppConfig.taskAnswersTarget * 2 + 1;

      for (var i = 0; i < answers; i++) {
        await p.recordCorrectAnswer();
        if (i == AppConfig.taskAnswersTarget) {
          await p.claimTask(TaskKind.correctAnswers);
        }
      }

      final task =
          p.tasks.firstWhere((t) => t.kind == TaskKind.correctAnswers);
      expect(task.progress, answers, reason: 'التقدّم نفسه يستمر بعد الهدف');
      expect(task.shownProgress, AppConfig.taskAnswersTarget);
    });

    test('الاستلام يمنح العملات مرة واحدة فقط', () async {
      final p = await _provider();
      await p.recordDailyCompleted();

      final first = await p.claimTask(TaskKind.completeDaily);
      expect(first, AppConfig.coinsTaskDaily);
      expect(p.coins, AppConfig.coinsTaskDaily);

      final second = await p.claimTask(TaskKind.completeDaily);
      expect(second, 0);
      expect(p.coins, AppConfig.coinsTaskDaily);
    });

    test('لا يمكن استلام مهمة غير مكتملة', () async {
      final p = await _provider();

      expect(await p.claimTask(TaskKind.completeLevel), 0);
      expect(p.coins, 0);
    });

    test('المستوى يُحتسب عند الاجتياز', () async {
      final p = await _provider();
      await p.recordLevelCompleted();

      final task = p.tasks.firstWhere((t) => t.kind == TaskKind.completeLevel);
      expect(task.isClaimable, isTrue);
    });

    test('الصندوق يُفتح بعد استلام كل المهام فقط', () async {
      final p = await _provider();

      expect(p.chestReady, isFalse);

      await p.recordDailyCompleted();
      await p.recordLevelCompleted();
      for (var i = 0; i < AppConfig.taskAnswersTarget; i++) {
        await p.recordCorrectAnswer();
      }

      // مكتملة لكن غير مستلَمة بعد.
      expect(p.chestReady, isFalse);

      await p.claimTask(TaskKind.completeDaily);
      await p.claimTask(TaskKind.completeLevel);
      await p.claimTask(TaskKind.correctAnswers);

      expect(p.chestReady, isTrue);

      final reward = await p.claimChest();
      expect(reward, AppConfig.coinsChestBonus);
      expect(p.chestClaimed, isTrue);
      expect(await p.claimChest(), 0);
    });

    test('تقدّم المهام يُصفَّر مع تغيّر اليوم دون مسّ العملات', () {
      const regen = RegenerateHearts();
      final now = DateTime(2026, 8, 4, 9);

      final result = regen(
        const Economy(
          coins: 500,
          bonusHints: 4,
          tasksDayKey: '2026-08-03',
          correctAnswersToday: 10,
          levelsCompletedToday: 2,
          dailyDoneToday: true,
          claimedTaskIds: {'answers', 'daily'},
          chestClaimed: true,
        ),
        now: now,
      );

      expect(result.economy.correctAnswersToday, 0);
      expect(result.economy.levelsCompletedToday, 0);
      expect(result.economy.dailyDoneToday, isFalse);
      expect(result.economy.claimedTaskIds, isEmpty);
      expect(result.economy.chestClaimed, isFalse);
      expect(result.economy.tasksDayKey, DayKey.from(now));

      // العملات والمساعدات المشتراة ليست يومية.
      expect(result.economy.coins, 500);
      expect(result.economy.bonusHints, 4);
    });
  });

  group('المتجر', () {
    test('ملء القلوب يخصم العملات ويرفع الرصيد للحد الأقصى', () async {
      final p = await _provider(
        Economy(
          hearts: 1,
          coins: AppConfig.priceHeartsRefill,
          lastRegenAtIso: DateTime.now().toIso8601String(),
        ),
      );

      expect(p.canBuyHeartsRefill, isTrue);
      expect(await p.buyHeartsRefill(), isTrue);
      expect(p.hearts, AppConfig.maxHearts);
      expect(p.coins, 0);
    });

    test('لا شراء بعملات غير كافية', () async {
      final p = await _provider(
        Economy(
          hearts: 1,
          coins: AppConfig.priceHeartsRefill - 1,
          lastRegenAtIso: DateTime.now().toIso8601String(),
        ),
      );

      expect(p.canBuyHeartsRefill, isFalse);
      expect(await p.buyHeartsRefill(), isFalse);
      expect(p.hearts, 1);
    });

    test('لا شراء والقلوب ممتلئة', () async {
      final p = await _provider(
        const Economy(coins: 9999),
      );

      expect(p.isFull, isTrue);
      expect(p.canBuyHeartsRefill, isFalse);
    });

    test('حزمة المساعدات تُضاف فوق المجانية ولا تُصفَّر يومياً', () async {
      final p = await _provider(const Economy(coins: AppConfig.priceHintsPack));

      final before = p.hintsLeft;
      expect(await p.buyHintsPack(), isTrue);

      expect(p.hintsLeft, before + AppConfig.hintsPerPack);
      expect(p.coins, 0);
    });

    test('المساعدات المجانية تُستهلك قبل المشتراة', () async {
      final p = await _provider(const Economy(coins: AppConfig.priceHintsPack));
      await p.buyHintsPack();

      // استهلاك كل المجانية.
      for (var i = 0; i < AppConfig.freeHintsPerDay; i++) {
        await p.consumeHint();
      }
      expect(p.freeHintsLeft, 0);
      expect(p.hintsLeft, AppConfig.hintsPerPack);

      // ثم تبدأ المشتراة بالنقصان.
      await p.consumeHint();
      expect(p.hintsLeft, AppConfig.hintsPerPack - 1);
    });
  });
}
