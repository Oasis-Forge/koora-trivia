import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/data/models/question_model.dart';
import 'package:football_trivia/domain/entities/app_settings.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/ad_service.dart';
import 'package:football_trivia/domain/repositories/economy_repository.dart';
import 'package:football_trivia/domain/repositories/progress_repository.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/domain/repositories/reminder_scheduler.dart';
import 'package:football_trivia/domain/repositories/settings_repository.dart';
import 'package:football_trivia/domain/repositories/stats_repository.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/screens/quiz_screen.dart';
import 'package:football_trivia/presentation/screens/score_screen.dart';
import 'package:provider/provider.dart';

/// عشرة أسئلة، الإجابة الصحيحة دائماً الخيار الأول.
List<Question> _questions(String slug) => [
      for (var i = 1; i <= 10; i++)
        QuestionModel(
          id: 1000 + i,
          category: slug,
          categoryName: 'ألفا',
          level: 1,
          text: 'سؤال $i',
          options: const ['أ', 'ب', 'ج', 'د'],
          answerIndex: 0,
        ),
    ];

class _FakeQuizRepository implements QuizRepository {
  @override
  Future<List<Category>> getCategories() async => const [
        Category(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1),
      ];

  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async =>
      _questions(categorySlug);

  @override
  Future<int> getLevelCount(String categorySlug) async => 10;

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  }) async =>
      _questions('alpha');

  @override
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  }) async =>
      const [];
}

class _FakeEconomyRepository implements EconomyRepository {
  _FakeEconomyRepository(this.economy);
  Economy economy;

  @override
  Future<Economy> load() async => economy;

  @override
  Future<void> save(Economy value) async => economy = value;
}

class _FakeStatsRepository implements StatsRepository {
  UserStats stats = const UserStats();

  @override
  Future<UserStats> load() async => stats;

  @override
  Future<void> save(UserStats value) async => stats = value;
}

class _FakeProgressRepository implements ProgressRepository {
  Map<String, CategoryProgress> data = {};

  @override
  Future<Map<String, CategoryProgress>> loadAll() async => data;

  @override
  Future<void> save(CategoryProgress progress) async =>
      data[progress.slug] = progress;

  @override
  Future<void> clear() async => data = {};
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings();

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings value) async => settings = value;
}

class _FakeScheduler implements ReminderScheduler {
  @override
  Future<void> init() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {}

  @override
  Future<void> cancelDaily() async {}
}

class _FakeAdService implements AdService {
  @override
  Future<void> init() async {}

  @override
  set onChanged(void Function()? listener) {}

  @override
  bool get isRewardedReady => false;

  @override
  bool get isPrivacyOptionsRequired => false;

  @override
  Future<bool> showPrivacyOptions() async => false;

  @override
  void onAppResumed() {}

  @override
  Future<RewardResult> showRewarded() async => RewardResult.unavailable;

  @override
  void recordRoundFinished() {}

  @override
  Future<bool> maybeShowInterstitial() async => false;

  @override
  set adsRemoved(bool value) {}
}

/// يلعب جولة كاملة ثم يعرض شاشة النتيجة، مع بديل لشاشة السؤال يكشف أي انتقال إليها.
Future<QuizProvider> _pumpScoreScreen(
  WidgetTester tester, {
  required int hearts,
  required int correct,
  bool levelMode = true,
}) async {
  final quiz = QuizProvider(repository: _FakeQuizRepository());
  final economy = EconomyProvider(
    repository: _FakeEconomyRepository(
      Economy(hearts: hearts, lastRegenAtIso: DateTime.now().toIso8601String()),
    ),
  );
  final stats = StatsProvider(repository: _FakeStatsRepository());
  final progress = ProgressProvider(repository: _FakeProgressRepository());
  final settings = SettingsProvider(
    repository: _FakeSettingsRepository(),
    scheduler: _FakeScheduler(),
  );
  final ads = AdsProvider(service: _FakeAdService());

  await economy.init();
  await stats.init();
  await progress.init();
  await settings.init();
  await quiz.loadCategories();

  if (levelMode) {
    await quiz.startLevel(categorySlug: 'alpha', level: 1);
  } else {
    await quiz.startQuickPlay();
  }
  for (var i = 0; i < 10; i++) {
    quiz.selectAnswer(i < correct ? 0 : 1);
    quiz.next();
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: economy),
        ChangeNotifierProvider.value(value: stats),
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: ads),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: ScoreScreen(),
        ),
        routes: {
          QuizScreen.routeName: (_) => const Scaffold(body: Text('quiz-screen')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return quiz;
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 200);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('إعادة المستوى بلا قلوب تعرض حوار القلوب ولا تبدأ المستوى',
      (tester) async {
    final quiz = await _pumpScoreScreen(tester, hearts: 0, correct: 3);

    await _tapButton(tester, AppStrings.replayLevel);

    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);
    expect(find.text('quiz-screen'), findsNothing);
    expect(quiz.status, isNot(QuizStatus.playing));
    quiz.abandon();
  });

  testWidgets('المستوى التالي بلا قلوب يعرض حوار القلوب ولا يبدأ المستوى',
      (tester) async {
    // اجتياز المستوى ممكن رغم نفاد القلوب أثناءه: الأخطاء الثلاثة تستهلكها.
    final quiz = await _pumpScoreScreen(tester, hearts: 0, correct: 10);

    await _tapButton(tester, AppStrings.nextLevel);

    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);
    expect(find.text('quiz-screen'), findsNothing);
    expect(quiz.status, isNot(QuizStatus.playing));
    quiz.abandon();
  });

  testWidgets('إعادة المستوى مع قلوب تبدأ المستوى مباشرة', (tester) async {
    final quiz = await _pumpScoreScreen(tester, hearts: 3, correct: 3);

    await _tapButton(tester, AppStrings.replayLevel);

    expect(find.text('quiz-screen'), findsOneWidget);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    quiz.abandon();
  });

  testWidgets('اللعب السريع يبقى مجانياً حتى بلا قلوب', (tester) async {
    final quiz = await _pumpScoreScreen(
      tester,
      hearts: 0,
      correct: 3,
      levelMode: false,
    );

    await _tapButton(tester, AppStrings.playAgain);

    expect(find.text('quiz-screen'), findsOneWidget);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    quiz.abandon();
  });
}
