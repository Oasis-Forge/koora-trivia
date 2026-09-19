import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/data/models/user_stats_model.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/usecases/update_streak.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/buy_streak_shield.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/purchases_provider.dart';
import 'package:football_trivia/presentation/providers/record_round.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/screens/shop_screen.dart';
import 'package:football_trivia/presentation/widgets/surface.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_billing_service.dart';
import 'fakes/fake_repositories.dart';
import 'fakes/score_screen_harness.dart';

/// مفتاح يوم قبل اليوم بـ[days] أيام، بالتقويم لا بـ24 ساعة.
String _daysAgo(int days, [DateTime? now]) {
  final n = now ?? DateTime.now();
  return DayKey.from(DateTime(n.year, n.month, n.day - days));
}

/// تحدي يوم مكتمل بسبع إجابات صحيحة.
QuizResult _daily() {
  final questions = fakeQuestions(AppConfig.dailyQuestionCount);
  return QuizResult(
    answers: [
      for (final q in questions)
        AnswerRecord(
          question: q,
          selectedIndex: 0,
          earnedPoints: 100,
          secondsLeft: 10,
        ),
    ],
    score: 700,
    isDaily: true,
    playedAt: DateTime.now(),
    dailyDayKey: DayKey.today(),
  );
}

void main() {
  const update = UpdateStreak();

  group('الحماية في حساب السلسلة', () {
    test('فاته يوم واحد ومعه حماية: تستمر السلسلة وتُستعمل الحماية', () {
      const stats = UserStats(
        currentStreak: 12,
        bestStreak: 12,
        lastDailyDayKey: '2026-09-17',
        streakShields: 1,
      );

      final after = update(stats, todayKey: '2026-09-19');

      expect(after.currentStreak, 13);
      expect(after.streakShields, 0);
      expect(UpdateStreak.changes(stats, after).shieldUsed, isTrue);
    });

    test('فاته يومان: تنقطع السلسلة وتبقى الحماية له', () {
      const stats = UserStats(
        currentStreak: 12,
        bestStreak: 12,
        lastDailyDayKey: '2026-09-16',
        streakShields: 1,
      );

      final after = update(stats, todayKey: '2026-09-19');

      expect(after.currentStreak, 1);
      expect(after.streakShields, 1);
    });

    test('يوم متتالٍ لا يستعمل الحماية', () {
      const stats = UserStats(
        currentStreak: 3,
        bestStreak: 3,
        lastDailyDayKey: '2026-09-18',
        streakShields: 1,
      );

      expect(update(stats, todayKey: '2026-09-19').streakShields, 1);
    });

    test('السلسلة تبقى ظاهرة في اليوم التالي للفائت ما دامت الحماية معه', () {
      const stats = UserStats(
        currentStreak: 12,
        lastDailyDayKey: '2026-09-17',
        streakShields: 1,
      );

      expect(UpdateStreak.visibleStreak(stats, '2026-09-19'), 12);
      expect(UpdateStreak.visibleStreak(stats, '2026-09-20'), 0);
      expect(
        UpdateStreak.visibleStreak(
          stats.copyWith(streakShields: 0),
          '2026-09-19',
        ),
        0,
      );
    });
  });

  group('مكافآت أيام السلسلة', () {
    test('بلوغ 7 أيام أول مرة يمنح عملاته', () {
      const stats = UserStats(
        currentStreak: 6,
        bestStreak: 6,
        lastDailyDayKey: '2026-09-18',
      );
      final after = update(stats, todayKey: '2026-09-19');

      expect(
        UpdateStreak.changes(stats, after).rewardCoins,
        AppConfig.streakMilestoneCoins[7],
      );
    });

    test('من بلغ 7 قبلاً ثم أعاد بناء سلسلته لا يأخذها ثانية', () {
      const stats = UserStats(
        currentStreak: 6,
        bestStreak: 20,
        lastDailyDayKey: '2026-09-18',
      );
      final after = update(stats, todayKey: '2026-09-19');

      expect(UpdateStreak.changes(stats, after).rewardCoins, 0);
    });
  });

  group('الشراء', () {
    late StatsProvider stats;
    late EconomyProvider economy;

    Future<void> setUp({required int coins, int shields = 0}) async {
      stats = StatsProvider(
        repository: FakeStatsRepository(UserStats(streakShields: shields)),
      );
      economy = EconomyProvider(
        repository: FakeEconomyRepository(Economy(coins: coins)),
      );
      await Future.wait([stats.init(), economy.init()]);
    }

    BuyStreakShield buy() => BuyStreakShield(stats: stats, economy: economy);

    test('يخصم السعر ويضيف حماية', () async {
      await setUp(coins: AppConfig.priceStreakShield + 10);

      expect(await buy()(), isTrue);
      expect(economy.coins, 10);
      expect(stats.streakShields, 1);
    });

    test('حماية واحدة فقط: الشراء الثاني لا يخصم شيئاً', () async {
      await setUp(coins: 1000, shields: 1);

      expect(await buy()(), isFalse);
      expect(economy.coins, 1000);
      expect(stats.streakShields, 1);
    });

    test('عملات لا تكفي: لا حماية', () async {
      await setUp(coins: AppConfig.priceStreakShield - 1);

      expect(await buy()(), isFalse);
      expect(stats.streakShields, 0);
    });

    test('نسخة معدّلة تحمل عشر حمايات تُقرأ واحدة', () {
      final model = UserStatsModel.fromJson({'streakShields': 10});
      expect(model.streakShields, AppConfig.maxStreakShields);
      expect(UserStatsModel.fromEntity(model).toJson()['streakShields'], 1);
    });
  });

  group('حفظ الجولة', () {
    test('تحدي اليوم السابع يمنح عملات السلسلة مرة واحدة', () async {
      final stats = StatsProvider(
        repository: FakeStatsRepository(
          UserStats(
            currentStreak: 6,
            bestStreak: 6,
            lastDailyDayKey: _daysAgo(1),
          ),
        ),
      );
      final economy = EconomyProvider(repository: FakeEconomyRepository());
      final progress = ProgressProvider(repository: FakeProgressRepository());
      await Future.wait([stats.init(), economy.init(), progress.init()]);
      final record =
          RecordRound(stats: stats, economy: economy, progress: progress);

      final round = await record(_daily());
      expect(round.streak.rewardCoins, AppConfig.streakMilestoneCoins[7]);
      expect(economy.coins, AppConfig.streakMilestoneCoins[7]);

      // النتيجة نفسها مرة ثانية (إعادة بناء الشاشة) لا تمنح شيئاً.
      await record(_daily());
      expect(economy.coins, AppConfig.streakMilestoneCoins[7]);
    });
  });

  group('الواجهة', () {
    testWidgets('المتجر: شراء الحماية ثم «لديك حماية»', (tester) async {
      final stats = StatsProvider(repository: FakeStatsRepository());
      final economy = EconomyProvider(
        repository: FakeEconomyRepository(
          const Economy(coins: AppConfig.priceStreakShield),
        ),
      );
      await Future.wait([stats.init(), economy.init()]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: stats),
            ChangeNotifierProvider.value(value: economy),
            ChangeNotifierProvider(
              create: (_) => AdsProvider(service: FakeAdService(ready: false)),
            ),
            ChangeNotifierProvider(
              create: (_) => PurchasesProvider(
                service: FakeBillingService(available: false),
                grantCoins: (_) async {},
                onAdsRemoved: () {},
              )..init(),
            ),
          ],
          child: const MaterialApp(home: ShopScreen()),
        ),
      );
      await tester.pump();

      final row = find
          .ancestor(
            of: find.text(AppStrings.streakShield),
            matching: find.byType(Surface),
          )
          .first;
      // الأخير زر السعر؛ `Surface` نفسها قد تكون قابلة للمس.
      await tester
          .tap(find.descendant(of: row, matching: find.byType(InkWell)).last);
      await tester.pump();

      expect(stats.streakShields, 1);
      expect(economy.coins, 0);
      expect(find.text(AppStrings.streakShieldHeld), findsOneWidget);
    });

    Future<void> tall(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('النتيجة تقول إن الحماية حفظت السلسلة', (tester) async {
      await tall(tester);
      final now = DateTime.now();
      final quiz = await pumpScoreScreen(
        tester,
        correct: 7,
        mode: RoundMode.daily,
        stats: UserStats(
          currentStreak: 4,
          bestStreak: 4,
          lastDailyDayKey: _daysAgo(2, now),
          streakShields: 1,
        ),
        clock: () => now,
      );

      expect(find.text(AppStrings.streakShieldUsed), findsOneWidget);
      quiz.abandon();
    });

    testWidgets('النتيجة تعرض مكافأة اليوم السابع', (tester) async {
      await tall(tester);
      final now = DateTime.now();
      final quiz = await pumpScoreScreen(
        tester,
        correct: 7,
        mode: RoundMode.daily,
        stats: UserStats(
          currentStreak: 6,
          bestStreak: 6,
          lastDailyDayKey: _daysAgo(1, now),
        ),
        clock: () => now,
      );

      expect(
        find.text(AppStrings.streakReward(AppConfig.streakMilestoneCoins[7]!)),
        findsOneWidget,
      );
      quiz.abandon();
    });
  });
}
