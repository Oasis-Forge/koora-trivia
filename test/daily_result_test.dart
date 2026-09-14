import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/core/theme/app_colors.dart';
import 'package:football_trivia/presentation/providers/settings_provider.dart';
import 'package:football_trivia/presentation/screens/score_screen.dart';
import 'package:provider/provider.dart';

import 'fakes/score_screen_harness.dart';

SettingsProvider _settings(WidgetTester tester) =>
    Provider.of<SettingsProvider>(
      tester.element(find.byType(ScoreScreen)),
      listen: false,
    );

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 200);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// نهاية تحدي اليوم: قلب حقيقي فقط، تذكير الغد بلمسة، وطريق إلى المستويات.
void main() {
  testWidgets('«كسبت قلباً!» تظهر حين يُضاف قلب فعلاً', (tester) async {
    final quiz = await pumpScoreScreen(
      tester,
      correct: 5,
      mode: RoundMode.daily,
      hearts: 3,
    );

    expect(find.text(AppStrings.heartEarned, skipOffstage: false), findsOneWidget);
    quiz.abandon();
  });

  testWidgets('لا «كسبت قلباً!» والقلوب ممتلئة', (tester) async {
    final quiz =
        await pumpScoreScreen(tester, correct: 5, mode: RoundMode.daily);

    expect(find.text(AppStrings.heartEarned, skipOffstage: false), findsNothing);
    quiz.abandon();
  });

  testWidgets('بطاقة تذكير الغد تفعّل التنبيه بلمسة وتؤكّد الموعد',
      (tester) async {
    final quiz =
        await pumpScoreScreen(tester, correct: 5, mode: RoundMode.daily);
    expect(_settings(tester).reminderEnabled, isFalse);
    // ذهبي مقروء على البطاقة الخضراء، لا لون الزر الافتراضي.
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, AppStrings.dailyReminderButton),
    );
    expect(button.style?.foregroundColor?.resolve({}), AppColors.gold);

    await _tap(tester, AppStrings.dailyReminderButton);

    expect(_settings(tester).reminderEnabled, isTrue);
    expect(
      find.text(AppStrings.dailyReminderSet(
        _settings(tester).reminderTimeLabel(tester.element(find.byType(Scaffold).first)),
      )),
      findsOneWidget,
    );
    expect(find.text(AppStrings.dailyReminderAsk), findsNothing);
    quiz.abandon();
  });

  testWidgets('«العب مستوى» بعد تحدي اليوم يفتح التصنيفات', (tester) async {
    final quiz =
        await pumpScoreScreen(tester, correct: 5, mode: RoundMode.daily);

    await _tap(tester, AppStrings.playLevel);

    expect(find.text(categoriesScreenStub), findsOneWidget);
    quiz.abandon();
  });

  testWidgets('لا بطاقة تذكير ولا «العب مستوى» بعد اللعب السريع', (tester) async {
    final quiz =
        await pumpScoreScreen(tester, correct: 5, mode: RoundMode.quickPlay);

    expect(find.text(AppStrings.dailyReminderAsk, skipOffstage: false),
        findsNothing);
    expect(find.text(AppStrings.playLevel, skipOffstage: false), findsNothing);
    quiz.abandon();
  });
}
