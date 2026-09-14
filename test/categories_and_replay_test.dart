import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/category.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/screens/categories_screen.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_repositories.dart';
import 'fakes/score_screen_harness.dart';

/// أول تحميل للتصنيفات يرمي، وما بعده ينجح.
class _FlakyQuizRepository extends FakeQuizRepository {
  int calls = 0;

  @override
  Future<List<Category>> getCategories() async {
    calls++;
    if (calls == 1) throw StateError('ملف أسئلة تالف');
    return super.getCategories();
  }
}

/// يسجّل التصنيف المطلوب في كل جولة لعب سريع.
class _RecordingQuizRepository extends FakeQuizRepository {
  final requested = <String?>[];

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  }) {
    requested.add(categorySlug);
    return super.getRandomQuestions(count: count, categorySlug: categorySlug);
  }
}

void main() {
  test('فشل تحميل التصنيفات يُعلَن ويُسجَّل، وإعادة المحاولة تنجح', () async {
    final reported = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = original);

    final quiz = QuizProvider(repository: _FlakyQuizRepository());
    await quiz.loadCategories();
    expect(quiz.categoriesFailed, isTrue);
    expect(quiz.categories, isEmpty);
    expect(reported, hasLength(1));

    await quiz.loadCategories();
    expect(quiz.categoriesFailed, isFalse);
    expect(quiz.categories, isNotEmpty);
  });

  testWidgets('شاشة التصنيفات تعرض الخطأ وزر إعادة المحاولة بدل انتظار لا ينتهي',
      (tester) async {
    final reported = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = reported.add;
    try {
      final progress = ProgressProvider(repository: FakeProgressRepository());
      await progress.init();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => QuizProvider(repository: _FlakyQuizRepository()),
            ),
            ChangeNotifierProvider.value(value: progress),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loadCategoriesFailed), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loadCategoriesFailed), findsNothing);
      expect(find.text('ألفا'), findsOneWidget);
      expect(reported, hasLength(1));
    } finally {
      FlutterError.onError = original;
    }
  });

  testWidgets('«العب مرة أخرى» بعد لعب سريع في تصنيف تعيده في التصنيف نفسه',
      (tester) async {
    final repository = _RecordingQuizRepository();
    final quiz = await pumpScoreScreen(
      tester,
      correct: 5,
      mode: RoundMode.quickPlay,
      quickPlayCategory: 'alpha',
      quizRepository: repository,
    );

    await tester.ensureVisible(find.text(AppStrings.playAgain));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.playAgain));
    await tester.pumpAndSettle();

    expect(find.text(quizScreenStub), findsOneWidget);
    expect(repository.requested, ['alpha', 'alpha']);

    await tester.pumpWidget(const SizedBox());
    quiz.dispose();
  });
}
