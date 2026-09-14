import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';

import 'fakes/score_screen_harness.dart';

/// شاشة طويلة تبني كل عناصر القائمة، فغياب زر لا يعني أنه خارج المنطقة المبنية.
Future<QuizProvider> _pump(
  WidgetTester tester, {
  required int correct,
  RoundMode mode = RoundMode.level,
  int level = 1,
  bool skipFirst = false,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final quiz = await pumpScoreScreen(
    tester,
    correct: correct,
    mode: mode,
    level: level,
    skipFirst: skipFirst,
  );
  // آخر عنصر مبني = كل ما فوقه مبني أيضاً: آخر صف في المراجعة، أو زر الرئيسية
  // بعد المستوى الذي لا مراجعة فيه.
  if (mode == RoundMode.level) {
    expect(find.text(AppStrings.backHome), findsOneWidget);
  } else {
    expect(find.text('سؤال ${quiz.total}'), findsOneWidget);
  }
  return quiz;
}

void main() {
  testWidgets('اجتياز مستوى: «المستوى التالي» و«أعد المستوى»', (tester) async {
    final quiz = await _pump(tester, correct: 10);

    expect(find.text(AppStrings.levelPassed), findsOneWidget);
    expect(find.text(AppStrings.nextLevel), findsOneWidget);
    expect(find.text(AppStrings.replayLevel), findsOneWidget);
    expect(find.text(AppStrings.playAgain), findsNothing);
    // لا مراجعة للإجابات بعد المستوى.
    expect(find.text(AppStrings.reviewAnswers), findsNothing);
    expect(find.text('سؤال 1'), findsNothing);
    quiz.abandon();
  });

  testWidgets('إخفاق في مستوى: «أعد المستوى» بلا «المستوى التالي»',
      (tester) async {
    final quiz = await _pump(tester, correct: 3);

    expect(find.text(AppStrings.levelFailed), findsOneWidget);
    expect(find.text(AppStrings.replayLevel), findsOneWidget);
    expect(find.text(AppStrings.nextLevel), findsNothing);
    quiz.abandon();
  });

  testWidgets('اجتياز آخر مستوى في التصنيف: لا «المستوى التالي»',
      (tester) async {
    final quiz = await _pump(
      tester,
      correct: 10,
      level: AppConfig.levelsPerCategory,
    );

    expect(find.text(AppStrings.levelPassed), findsOneWidget);
    expect(find.text(AppStrings.nextLevel), findsNothing);
    expect(find.text(AppStrings.replayLevel), findsOneWidget);
    quiz.abandon();
  });

  testWidgets('تحدي اليوم: لا إعادة ولا مستوى تالٍ، والمشاركة والرئيسية باقيتان',
      (tester) async {
    final quiz = await _pump(tester, correct: 5, mode: RoundMode.daily);

    expect(find.text(AppStrings.playAgain), findsNothing);
    expect(find.text(AppStrings.replayLevel), findsNothing);
    expect(find.text(AppStrings.nextLevel), findsNothing);
    expect(find.text(AppStrings.shareScore), findsOneWidget);
    expect(find.text(AppStrings.backHome), findsOneWidget);
    expect(find.text(AppStrings.reviewAnswers), findsOneWidget);
    quiz.abandon();
  });

  testWidgets('اللعب السريع: «العب مرة أخرى» وحده', (tester) async {
    final quiz = await _pump(tester, correct: 4, mode: RoundMode.quickPlay);

    expect(find.text(AppStrings.playAgain), findsOneWidget);
    expect(find.text(AppStrings.replayLevel), findsNothing);
    expect(find.text(AppStrings.nextLevel), findsNothing);
    expect(find.text(AppStrings.reviewAnswers), findsOneWidget);
    quiz.abandon();
  });

  testWidgets('السؤال المتخطّى يظهر في المراجعة كتخطٍّ لا كخطأ', (tester) async {
    // الأول متخطّى، ثم أربع صحيحة، ثم خمس خاطئة.
    final quiz = await _pump(
      tester,
      correct: 5,
      mode: RoundMode.quickPlay,
      skipFirst: true,
    );

    expect(find.textContaining(AppStrings.skippedAnswer), findsOneWidget);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(5));
    quiz.abandon();
  });
}
