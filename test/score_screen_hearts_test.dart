import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';

import 'fakes/score_screen_harness.dart';

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 200);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('إعادة المستوى بلا قلوب تعرض حوار القلوب ولا تبدأ المستوى',
      (tester) async {
    final quiz = await pumpScoreScreen(tester, hearts: 0, correct: 3);

    await _tapButton(tester, AppStrings.replayLevel);

    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);
    expect(find.text(quizScreenStub), findsNothing);
    expect(quiz.status, isNot(QuizStatus.playing));
    quiz.abandon();
  });

  testWidgets('المستوى التالي بلا قلوب يعرض حوار القلوب ولا يبدأ المستوى',
      (tester) async {
    // اجتياز المستوى ممكن رغم نفاد القلوب أثناءه: الأخطاء الثلاثة تستهلكها.
    final quiz = await pumpScoreScreen(tester, hearts: 0, correct: 10);

    await _tapButton(tester, AppStrings.nextLevel);

    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);
    expect(find.text(quizScreenStub), findsNothing);
    expect(quiz.status, isNot(QuizStatus.playing));
    quiz.abandon();
  });

  testWidgets('إعادة المستوى مع قلوب تبدأ المستوى مباشرة', (tester) async {
    final quiz = await pumpScoreScreen(tester, hearts: 3, correct: 3);

    await _tapButton(tester, AppStrings.replayLevel);

    expect(find.text(quizScreenStub), findsOneWidget);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    quiz.abandon();
  });

  testWidgets('اللعب السريع يبقى مجانياً حتى بلا قلوب', (tester) async {
    final quiz = await pumpScoreScreen(
      tester,
      hearts: 0,
      correct: 3,
      mode: RoundMode.quickPlay,
    );

    await _tapButton(tester, AppStrings.playAgain);

    expect(find.text(quizScreenStub), findsOneWidget);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    quiz.abandon();
  });
}
