import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/domain/repositories/stats_repository.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/screens/quiz_screen.dart';
import 'package:football_trivia/presentation/widgets/hearts_bar.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';

List<Question> _questions(int count) => [
      for (var i = 1; i <= count; i++)
        Question(
          id: 1000 + i,
          category: 'alpha',
          categoryName: 'ألفا',
          level: 1,
          text: 'سؤال $i',
          options: const ['أ', 'ب', 'ج', 'د'],
          answerIndex: 0,
        ),
    ];

class _FakeQuizRepository implements QuizRepository {
  @override
  Future<List<Category>> getCategories() async => const [];

  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async =>
      _questions(10);

  @override
  Future<int> getLevelCount(String categorySlug) async => 10;

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
    Set<int> avoid = const {},
    bool Function(Question question)? prefer,
  }) async =>
      _questions(count);

  @override
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  }) async =>
      _questions(count);
}

class _FakeEconomyRepository implements EconomyRepository {
  _FakeEconomyRepository(this.economy);
  Economy economy;

  /// إن وُجد، لا يكتمل الحفظ حتى يُكمله الاختبار.
  Completer<void>? saveGate;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async {
    economy = value;
    await saveGate?.future;
  }
}

class _FakeStatsRepository implements StatsRepository {
  _FakeStatsRepository(this.stats);
  UserStats stats;

  @override
  Future<UserStats> load() async => stats;

  @override
  Future<void> save(UserStats value) async => stats = value;
}

const _levelsScreen = 'شاشة المستويات';
const _startLevel = 'ابدأ مستوى';

class _Harness {
  late final _FakeEconomyRepository economyRepo;
  late final EconomyProvider economy;
  late final StatsProvider stats;
  late final QuizProvider quiz;
  DateTime now = DateTime.now();

  /// الرئيسية ثم شاشة تبدأ مستوى فوقها — حتى يظهر أي إغلاق زائد للشاشة.
  Future<void> pump(
    WidgetTester tester, {
    int hearts = 0,
    int coins = 0,
    bool dailyDone = false,
  }) async {
    economyRepo = _FakeEconomyRepository(
      Economy(
        hearts: hearts,
        coins: coins,
        lastRegenAtIso: now.toIso8601String(),
      ),
    );
    economy = EconomyProvider(repository: economyRepo, clock: () => now);
    stats = StatsProvider(
      repository: _FakeStatsRepository(
        dailyDone
            ? UserStats(currentStreak: 1, lastDailyDayKey: DayKey.today())
            : const UserStats(),
      ),
    );
    quiz = QuizProvider(repository: _FakeQuizRepository());
    await economy.init();
    await stats.init();

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: economy),
          ChangeNotifierProvider.value(value: stats),
          ChangeNotifierProvider.value(value: quiz),
          ChangeNotifierProvider(
            create: (_) => AdsProvider(service: FakeAdService(ready: false)),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          routes: {
            QuizScreen.routeName: (_) =>
                const Scaffold(body: Text('شاشة السؤال')),
          },
          home: const Scaffold(body: Text('الرئيسية')),
        ),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Column(
            children: [
              const Text(_levelsScreen),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => NoHeartsDialog.ensureHearts(context),
                  child: const Text(_startLevel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_startLevel));
    await tester.pumpAndSettle();
  }

  /// مؤقّت السؤال يعمل بعد بدء التحدي؛ نُزيل الشجرة ثم نتلف المزوّد.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    quiz.dispose();
  }
}

String get _refillLabel =>
    '${AppStrings.refillHearts} · ${AppConfig.priceHeartsRefill}';

void main() {
  testWidgets('بقلوب متاحة لا يظهر الحوار', (tester) async {
    final h = _Harness();
    await h.pump(tester, hearts: 2);

    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('تحدي اليوم لم يُنجز: الحوار يقترحه وزرّه يبدأ التحدي',
      (tester) async {
    final h = _Harness();
    await h.pump(tester);

    expect(find.text(AppStrings.noHeartsBody), findsOneWidget);

    await tester.tap(find.text(AppStrings.playDailyForHeart));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    expect(find.text('شاشة السؤال'), findsOneWidget);
    expect(h.quiz.isDaily, isTrue);
    await h.dispose(tester);
  });

  testWidgets('تحدي اليوم أُنجز: لا نصيحة به ولا زر له', (tester) async {
    final h = _Harness();
    await h.pump(tester, dailyDone: true);

    expect(find.text(AppStrings.noHeartsBodyDailyDone), findsOneWidget);
    expect(find.text(AppStrings.noHeartsBody), findsNothing);
    expect(find.text(AppStrings.playDailyForHeart), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('عملات لا تكفي: زر الملء معطّل مع السبب', (tester) async {
    final h = _Harness();
    await h.pump(tester, coins: AppConfig.priceHeartsRefill - 1);

    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text(_refillLabel),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text(AppStrings.notEnoughCoins), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('ملء القلوب بالعملات يملأ القلوب ويغلق الحوار', (tester) async {
    final h = _Harness();
    await h.pump(tester, coins: AppConfig.priceHeartsRefill + 50);

    await tester.tap(find.text(_refillLabel));
    await tester.pumpAndSettle();

    expect(h.economy.hearts, AppConfig.maxHearts);
    expect(h.economy.coins, 50);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    expect(find.text(_levelsScreen), findsOneWidget);
    expect(find.text(AppStrings.purchased), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('اكتمال الحفظ بعد إغلاق الحوار لا يغلق الشاشة التي تحته',
      (tester) async {
    final h = _Harness();
    await h.pump(tester, coins: AppConfig.priceHeartsRefill);

    h.economyRepo.saveGate = Completer<void>();
    await tester.tap(find.text(_refillLabel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);

    h.economyRepo.saveGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text(_levelsScreen), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('قلب يتجدّد والحوار مفتوح يغلق الحوار وحده', (tester) async {
    final h = _Harness();
    await h.pump(tester);
    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);

    h.now = h.now.add(
      const Duration(minutes: AppConfig.heartRegenMinutes, seconds: 30),
    );
    await tester.pump(
      const Duration(seconds: AppConfig.heartsRefreshSeconds),
    );
    await tester.pumpAndSettle();

    expect(h.economy.hearts, 1);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    expect(find.text(_levelsScreen), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('زر «حسناً» يغلق الحوار وحده', (tester) async {
    final h = _Harness();
    await h.pump(tester);

    await tester.tap(find.text(AppStrings.ok));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    expect(find.text(_levelsScreen), findsOneWidget);
    await h.dispose(tester);
  });
}
