import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/screens/score_screen.dart';
import 'package:provider/provider.dart';

import 'fakes/score_screen_harness.dart';

EconomyProvider _economy(WidgetTester tester) => Provider.of<EconomyProvider>(
      tester.element(find.byType(ScoreScreen)),
      listen: false,
    );

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 200);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('إعادة المستوى بلا قلوب تعرض حوار القلوب ولا تبدأ المستوى',
      (tester) async {
    // قلب المحاولة الأخير خُصم عند بدئها، والإخفاق لا يعيده.
    final quiz = await pumpScoreScreen(tester, hearts: 0, correct: 3);
    expect(find.text(AppStrings.heartLost, skipOffstage: false), findsOneWidget);
    expect(_economy(tester).hearts, 0);

    await _tapButton(tester, AppStrings.replayLevel);

    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);
    expect(find.text(quizScreenStub), findsNothing);
    expect(quiz.status, isNot(QuizStatus.playing));
    quiz.abandon();
  });

  testWidgets('اجتياز المستوى يعيد قلب المحاولة، فيبدأ المستوى التالي ويخصمه',
      (tester) async {
    // المحاولة بدأت بآخر قلب: خُصم عند البدء ويعود مع الاجتياز.
    final quiz = await pumpScoreScreen(tester, hearts: 0, correct: 10);
    expect(_economy(tester).hearts, 1);
    expect(find.text(AppStrings.heartLost, skipOffstage: false), findsNothing);

    final economy = _economy(tester);
    await _tapButton(tester, AppStrings.nextLevel);

    expect(find.text(quizScreenStub), findsOneWidget);
    expect(find.text(AppStrings.noHeartsTitle), findsNothing);
    expect(economy.hearts, 0);
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
