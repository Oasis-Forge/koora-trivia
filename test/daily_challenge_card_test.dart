import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/utils/arabic_count.dart';
import 'package:football_trivia/presentation/widgets/daily_challenge_card.dart';

void main() {
  testWidgets('قبل الإنجاز تعرض البطاقة عدد الأسئلة ومضاعف النقاط', (tester) async {
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

    final questions = ArabicCount.format(
      AppConfig.dailyQuestionCount,
      ArabicNoun.question,
    );
    expect(
      find.text(
        '$questions • نقاط مضاعفة ×${AppConfig.dailyMultiplier}',
      ),
      findsOneWidget,
    );
  });
}
