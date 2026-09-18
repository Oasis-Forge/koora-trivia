import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/widgets/koora_buttons.dart';

import 'fakes/score_screen_harness.dart';

/// شاشة طويلة تبني كل عناصر القائمة، فغياب زر لا يعني أنه خارج المنطقة المبنية.
Future<QuizProvider> _pump(
  WidgetTester tester, {
  required int correct,
  RoundMode mode = RoundMode.level,
  int level = 1,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final quiz = await pumpScoreScreen(
    tester,
    correct: correct,
    mode: mode,
    level: level,
  );
  // زر الرئيسية آخر عنصر في الشاشة: ظهوره يعني أن كل ما فوقه مبني.
  expect(find.text(AppStrings.backHome), findsOneWidget);
  // لا مراجعة للإجابات بعد أي جولة (قرار المالك): لا يظهر نص أي سؤال.
  expect(find.text('سؤال 1'), findsNothing);
  expect(find.text('سؤال ${quiz.total}'), findsNothing);
  return quiz;
}

void main() {
  testWidgets('اجتياز مستوى: «المستوى التالي» و«أعد المستوى»', (tester) async {
    final quiz = await _pump(tester, correct: 10);

    expect(find.text(AppStrings.levelPassed), findsOneWidget);
    expect(find.text(AppStrings.nextLevel), findsOneWidget);
    expect(find.text(AppStrings.replayLevel), findsOneWidget);
    expect(find.text(AppStrings.playAgain), findsNothing);
    quiz.abandon();
  });

  testWidgets('بعد الاجتياز «المستوى التالي» هو الزر الذهبي والمشاركة تحته',
      (tester) async {
    final quiz = await _pump(tester, correct: 10);

    final gold = find.byType(GoldButton);
    expect(
      find.descendant(of: gold, matching: find.text(AppStrings.nextLevel)),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text(AppStrings.nextLevel)).dy,
      lessThan(tester.getTopLeft(find.text(AppStrings.shareScore)).dy),
    );
    quiz.abandon();
  });

  testWidgets('إخفاق في مستوى: المشاركة تبقى الزر الذهبي', (tester) async {
    final quiz = await _pump(tester, correct: 3);

    expect(
      find.descendant(
        of: find.byType(GoldButton),
        matching: find.text(AppStrings.shareScore),
      ),
      findsOneWidget,
    );
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
    quiz.abandon();
  });

  testWidgets('اللعب السريع: «العب مرة أخرى» وحده', (tester) async {
    final quiz = await _pump(tester, correct: 4, mode: RoundMode.quickPlay);

    expect(find.text(AppStrings.playAgain), findsOneWidget);
    expect(find.text(AppStrings.replayLevel), findsNothing);
    expect(find.text(AppStrings.nextLevel), findsNothing);
    quiz.abandon();
  });
}
