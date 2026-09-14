import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/screens/quiz_screen.dart';
import 'package:football_trivia/presentation/screens/score_screen.dart';
import 'package:provider/provider.dart';

import 'fake_ad_service.dart';
import 'fake_repositories.dart';

enum RoundMode { level, quickPlay, daily }

/// نص شاشة السؤال البديلة — ظهوره يعني أن زراً بدأ جولة جديدة.
const quizScreenStub = 'quiz-screen';

/// يلعب جولة كاملة ثم يعرض شاشة النتيجة، مع بديل لشاشة السؤال يكشف أي انتقال إليها.
///
/// أول [correct] إجابات صحيحة والباقي خاطئ. [skipFirst] يتخطّى السؤال الأول
/// بمساعدة بدل الإجابة عنه.
Future<QuizProvider> pumpScoreScreen(
  WidgetTester tester, {
  required int correct,
  int hearts = AppConfig.maxHearts,
  RoundMode mode = RoundMode.level,
  int level = 1,
  bool skipFirst = false,
}) async {
  final quiz = QuizProvider(repository: FakeQuizRepository());
  final economy = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(hearts: hearts, lastRegenAtIso: DateTime.now().toIso8601String()),
    ),
  );
  final stats = StatsProvider(repository: FakeStatsRepository());
  final progress = ProgressProvider(repository: FakeProgressRepository());
  final settings = SettingsProvider(
    repository: FakeSettingsRepository(),
    scheduler: FakeScheduler(),
  );
  final ads = AdsProvider(service: FakeAdService(ready: false));

  await economy.init();
  await stats.init();
  await progress.init();
  await settings.init();
  await quiz.loadCategories();

  switch (mode) {
    case RoundMode.level:
      await quiz.startLevel(categorySlug: 'alpha', level: level);
    case RoundMode.quickPlay:
      await quiz.startQuickPlay();
    case RoundMode.daily:
      await quiz.startDaily();
  }
  for (var i = 0; i < quiz.total; i++) {
    if (skipFirst && i == 0) {
      quiz.skipQuestion();
    } else {
      quiz.selectAnswer(i < correct ? 0 : 1);
    }
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
          QuizScreen.routeName: (_) =>
              const Scaffold(body: Text(quizScreenStub)),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return quiz;
}
