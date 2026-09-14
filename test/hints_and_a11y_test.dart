import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/core/theme/app_colors.dart';
import 'package:football_trivia/core/utils/arabic_count.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/screens/shop_screen.dart';
import 'package:football_trivia/presentation/widgets/hearts_bar.dart';
import 'package:football_trivia/presentation/widgets/hint_bar.dart';
import 'package:football_trivia/presentation/widgets/star_row.dart';
import 'package:football_trivia/presentation/widgets/timer_ring.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_repositories.dart';
import 'fakes/score_screen_harness.dart';

EconomyProvider _economy({int hintsUsed = 0}) => EconomyProvider(
      repository: FakeEconomyRepository(
        Economy(
          hintsUsedToday: hintsUsed,
          hintsDayKey: DayKey.today(),
          lastRegenAtIso: DateTime.now().toIso8601String(),
        ),
      ),
    );

/// شريط المساعدات فوق مستوى بدأ للتوّ.
Future<(QuizProvider, EconomyProvider)> _pumpHintBar(
  WidgetTester tester, {
  int hintsUsed = 0,
}) async {
  final quiz = QuizProvider(repository: FakeQuizRepository());
  final economy = _economy(hintsUsed: hintsUsed);
  await economy.init();
  await quiz.startLevel(categorySlug: 'alpha', level: 1);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: quiz),
        ChangeNotifierProvider.value(value: economy),
      ],
      child: const MaterialApp(home: Scaffold(body: Center(child: HintBar()))),
    ),
  );
  return (quiz, economy);
}

/// عدّاد السؤال يعيد البناء كل ثانية فلا يستقر الإطار؛ ننتظر ظهور الشريط فقط.
Future<void> _showSnackBar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750));
}

Future<void> _dispose(WidgetTester tester, QuizProvider quiz) async {
  await tester.pumpWidget(const SizedBox());
  quiz.dispose();
}

void main() {
  group('شريط المساعدات', () {
    testWidgets('كل مساعدة مكتوب اسمها تحت أيقونتها', (tester) async {
      final (quiz, _) = await _pumpHintBar(tester);

      for (final label in const [
        AppStrings.hintFiftyFifty,
        AppStrings.hintSkip,
        AppStrings.hintExtraTime,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await _dispose(tester, quiz);
    });

    testWidgets('الوقت الإضافي المستخدَم يتعطّل ولمسه يشرح السبب', (tester) async {
      final (quiz, economy) = await _pumpHintBar(tester);

      await tester.tap(find.text(AppStrings.hintExtraTime));
      await tester.pump();
      expect(quiz.isExtraTimeUsed, isTrue);
      expect(economy.hintsLeft, AppConfig.freeHintsPerDay - 1);

      await tester.tap(find.text(AppStrings.hintExtraTime));
      await _showSnackBar(tester);
      expect(find.text(AppStrings.hintExtraTimeUsed), findsOneWidget);
      expect(economy.hintsLeft, AppConfig.freeHintsPerDay - 1);

      await _dispose(tester, quiz);
    });

    testWidgets('بلا مساعدات يشرح اللمس أنها انتهت ولا يطبّق شيئاً',
        (tester) async {
      final (quiz, _) =
          await _pumpHintBar(tester, hintsUsed: AppConfig.freeHintsPerDay);

      await tester.tap(find.text(AppStrings.hintFiftyFifty));
      await _showSnackBar(tester);
      expect(find.text(AppStrings.noHintsLeft), findsOneWidget);
      expect(quiz.isFiftyFiftyUsed, isFalse);

      await _dispose(tester, quiz);
    });
  });

  testWidgets('زر الشراء المعطّل في المتجر يقول لماذا', (tester) async {
    // قلوب ممتلئة وعملات صفر.
    final economy = _economy();
    await economy.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: economy),
          ChangeNotifierProvider(
            create: (_) => AdsProvider(service: FakeAdService(ready: false)),
          ),
        ],
        child: const MaterialApp(home: ShopScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.heartsAlreadyFull, skipOffstage: false),
        findsOneWidget);
    expect(find.text(AppStrings.notEnoughCoins, skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('المراجعة: إجابة اللاعب الخاطئة بالأحمر والصحيحة بالأخضر',
      (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // ثلاث صحيحة ثم سبع خاطئة يختار فيها اللاعب الخيار الثاني «ب».
    final quiz =
        await pumpScoreScreen(tester, correct: 3, mode: RoundMode.quickPlay);

    final correctLines = find.text(AppStrings.correctIs('أ'));
    expect(correctLines, findsNWidgets(7));
    expect(tester.widget<Text>(correctLines.first).style!.color,
        AppColors.correct);

    final picked = find.text(AppStrings.yourAnswerIs('ب'));
    expect(picked, findsNWidgets(7));
    expect(tester.widget<Text>(picked.first).style!.color, AppColors.wrong);

    quiz.abandon();
  });

  test('لكل IconButton تلميح يقرؤه قارئ الشاشة', () {
    final missing = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in RegExp(r'IconButton\(').allMatches(source)) {
        final end = (match.start + 400).clamp(0, source.length);
        if (!source.substring(match.start, end).contains('tooltip:')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          missing.add('${file.path}:${line + 1}');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  testWidgets('القلوب والعدّاد والنجوم لها تسميات لقارئ الشاشة', (tester) async {
    final handle = tester.ensureSemantics();
    final economy = _economy();
    await economy.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: economy,
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HeartsBar(),
                TimerRing(secondsLeft: 12),
                StarRow(earned: 2),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        AppStrings.heartsLabel(AppConfig.maxHearts, AppConfig.maxHearts),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(AppStrings.timeLeftLabel(12)), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        AppStrings.starsLabel(ArabicCount.format(2, ArabicNoun.star), 3),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
