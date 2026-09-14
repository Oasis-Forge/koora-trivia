import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/presentation/widgets/daily_challenge_card.dart';

void main() {
  testWidgets('قبل الإنجاز تعرض البطاقة مضاعف النقاط ووقت تجدد التحدي', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyChallengeCard(
            isDone: false,
            streak: 3,
            untilNext: const Duration(hours: 5),
            onPlay: () {},
          ),
        ),
      ),
    );

    expect(
      find.text(
        AppStrings.dailyMeta(
          '${AppConfig.dailyMultiplier}',
          AppStrings.hoursMinutes(5, 0),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.dailyStart), findsOneWidget);
  });
}
