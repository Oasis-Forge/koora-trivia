import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_repositories.dart';
import 'fakes/score_screen_harness.dart';

/// لاعب أكمل تحدي الأمس وسلسلته [streak]، فتحدي اليوم يرفعها واحداً.
///
/// [now] هو نفسه ساعة الإحصائيات، وإلا انقلب «الأمس» عند منتصف الليل.
UserStats _playedYesterday(int streak, DateTime now) => UserStats(
      currentStreak: streak,
      bestStreak: streak,
      lastDailyDayKey: DayKey.from(now.subtract(const Duration(days: 1))),
    );

/// شاشة طويلة تبني كل أزرار النتيجة دون تمرير.
void _showAllButtons(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('طلب التقييم من شاشة النتيجة', () {
    const minStreak = AppConfig.reviewPromptMinStreak;

    testWidgets('تحدي اليوم يبلغ بالسلسلة الحد: يُطلب', (tester) async {
      final prompter = FakeReviewPrompter();
      final now = DateTime.now();
      final quiz = await pumpScoreScreen(
        tester,
        correct: 3,
        mode: RoundMode.daily,
        stats: _playedYesterday(minStreak - 1, now),
        clock: () => now,
        reviewPrompter: prompter,
      );

      expect(prompter.asks, 1);
      quiz.abandon();
    });

    testWidgets('تحدي اليوم بسلسلة أقصر: لا يُطلب', (tester) async {
      final prompter = FakeReviewPrompter();
      final now = DateTime.now();
      final quiz = await pumpScoreScreen(
        tester,
        correct: 7,
        mode: RoundMode.daily,
        stats: _playedYesterday(minStreak - 2, now),
        clock: () => now,
        reviewPrompter: prompter,
      );

      expect(prompter.asks, 0);
      quiz.abandon();
    });

    testWidgets('ثلاث نجوم في مستوى: يُطلب', (tester) async {
      final prompter = FakeReviewPrompter();
      final quiz = await pumpScoreScreen(
        tester,
        correct: 10,
        reviewPrompter: prompter,
      );

      expect(prompter.asks, 1);
      quiz.abandon();
    });

    testWidgets('نجمتان أو مستوى فاشل: لا يُطلب', (tester) async {
      for (final correct in [9, 3]) {
        final prompter = FakeReviewPrompter();
        final quiz = await pumpScoreScreen(
          tester,
          correct: correct,
          reviewPrompter: prompter,
        );

        expect(prompter.asks, 0, reason: '$correct إجابات صحيحة');
        quiz.abandon();
      }
    });

    testWidgets('طُلب قبل أيام قليلة: لا يُطلب مجدداً', (tester) async {
      final prompter = FakeReviewPrompter(
        last: DateTime.now().subtract(const Duration(days: 3)),
      );
      final quiz = await pumpScoreScreen(
        tester,
        correct: 10,
        reviewPrompter: prompter,
      );

      expect(prompter.asks, 0);
      quiz.abandon();
    });

    testWidgets('بعد إعلان بيني: لا يُطلب', (tester) async {
      final prompter = FakeReviewPrompter();
      // الجولة التالية تكمل العدد فيُعرض الإعلان (المزيّف يتجاهل مفتاح الإطلاق).
      final ads = FakeAdService(ready: false)
        ..rounds = AppConfig.roundsBetweenInterstitials - 1;
      final quiz = await pumpScoreScreen(
        tester,
        correct: 10,
        reviewPrompter: prompter,
        adService: ads,
      );

      expect(ads.interstitialsShown, 1);
      expect(prompter.asks, 0);
      quiz.abandon();
    });

    testWidgets('غادر اللاعب قبل القرار: لا يُطلب فوق الجولة التالية',
        (tester) async {
      _showAllButtons(tester);
      final decision = Completer<void>();
      final prompter = FakeReviewPrompter(lastAskedGate: decision);
      final quiz = await pumpScoreScreen(
        tester,
        correct: 10,
        reviewPrompter: prompter,
      );

      await tester.tap(find.text(AppStrings.replayLevel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // شاشة النتيجة ما زالت تخرج (الانتقال جارٍ) حين يكتمل القرار.
      decision.complete();
      await tester.pumpAndSettle();

      expect(find.text(quizScreenStub), findsOneWidget);
      expect(prompter.asks, 0);
      quiz.abandon();
    });

    testWidgets('نافذة التقييم ما زالت تُطلب: «أعد المستوى» ينتظر إغلاقها',
        (tester) async {
      _showAllButtons(tester);
      final reviewSheet = Completer<void>();
      final prompter = FakeReviewPrompter(askGate: reviewSheet);
      final quiz = await pumpScoreScreen(
        tester,
        correct: 10,
        reviewPrompter: prompter,
      );
      expect(prompter.asks, 1);

      await tester.tap(find.text(AppStrings.replayLevel));
      await tester.pumpAndSettle();
      expect(find.text(quizScreenStub), findsNothing);

      reviewSheet.complete();
      await tester.pumpAndSettle();
      expect(find.text(quizScreenStub), findsOneWidget);
      quiz.abandon();
    });
  });

  testWidgets('كل صف في مراجعة الإجابات فيه زر «أبلغ عن خطأ»', (tester) async {
    _showAllButtons(tester);
    // المراجعة بعد اللعب السريع وتحدي اليوم فقط، لا بعد المستوى.
    final quiz =
        await pumpScoreScreen(tester, correct: 4, mode: RoundMode.quickPlay);

    expect(find.byTooltip(AppStrings.reportQuestion), findsNWidgets(10));
    quiz.abandon();
  });
}
