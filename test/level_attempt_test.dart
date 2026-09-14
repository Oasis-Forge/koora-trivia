import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/constants/app_strings.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/domain/repositories/quiz_repository.dart';
import 'package:football_trivia/domain/usecases/evaluate_level.dart';
import 'package:football_trivia/presentation/providers/ads_provider.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/quiz_provider.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';
import 'package:football_trivia/presentation/widgets/hearts_bar.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_ad_service.dart';
import 'fakes/fake_repositories.dart';

/// مستوى بلا أسئلة: تحميل فاشل دون استثناء.
class _EmptyLevelRepository extends FakeQuizRepository {
  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async =>
      const [];
}

/// زر يبدأ مستوى عبر `NoHeartsDialog.startLevel`، كما تفعل الشاشات.
class _Attempt {
  late final EconomyProvider economy;
  late final QuizProvider quiz;
  bool? started;

  Future<void> pump(
    WidgetTester tester, {
    required int hearts,
    QuizRepository? repository,
  }) async {
    economy = EconomyProvider(
      repository: FakeEconomyRepository(
        Economy(
          hearts: hearts,
          lastRegenAtIso: DateTime.now().toIso8601String(),
        ),
      ),
    );
    final stats = StatsProvider(repository: FakeStatsRepository(const UserStats()));
    quiz = QuizProvider(repository: repository ?? FakeQuizRepository());
    await economy.init();
    await stats.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: economy),
          ChangeNotifierProvider.value(value: stats),
          ChangeNotifierProvider.value(value: quiz),
          ChangeNotifierProvider(
            create: (_) => AdsProvider(service: FakeAdService(ready: false)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  started = await NoHeartsDialog.startLevel(
                    context,
                    categorySlug: 'alpha',
                    level: 1,
                  );
                },
                child: const Text('ابدأ'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
  }

  /// مؤقّت السؤال يعمل بعد البدء؛ نُزيل الشجرة ثم نتلف المزوّد.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    quiz.dispose();
  }
}

void main() {
  test('العتبات المعروضة قبل المستوى هي التي يطبّقها التقييم', () {
    const evaluate = EvaluateLevel();
    for (var total = 1; total <= 20; total++) {
      for (var stars = 1; stars <= 3; stars++) {
        final min = evaluate.minCorrectFor(stars, total: total);
        expect(evaluate.stars(correct: min, total: total),
            greaterThanOrEqualTo(stars));
        if (min > 0) {
          expect(evaluate.stars(correct: min - 1, total: total), lessThan(stars));
        }
      }
    }
    // 0.7 × 10 عشرياً أكبر قليلاً من 7، فالتقريب لأعلى كان سيعرض 8.
    const total = AppConfig.questionsPerLevel;
    expect(evaluate.minCorrectFor(1, total: total),
        (AppConfig.passRatio * total).round());
  });

  testWidgets('بدء المستوى يخصم قلباً واحداً للمحاولة', (tester) async {
    final h = _Attempt();
    await h.pump(tester, hearts: 3);

    expect(h.started, isTrue);
    expect(h.quiz.status, QuizStatus.playing);
    expect(h.economy.hearts, 2);

    await h.dispose(tester);
  });

  testWidgets('بلا قلوب يظهر الحوار ولا يبدأ المستوى', (tester) async {
    final h = _Attempt();
    await h.pump(tester, hearts: 0);

    expect(find.text(AppStrings.noHeartsTitle), findsOneWidget);
    expect(h.quiz.status, QuizStatus.idle);
    expect(h.economy.hearts, 0);

    await h.dispose(tester);
  });

  testWidgets('تعذّر تحميل أسئلة المستوى لا يخصم قلباً', (tester) async {
    final h = _Attempt();
    await h.pump(tester, hearts: 3, repository: _EmptyLevelRepository());

    expect(h.started, isTrue);
    expect(h.quiz.status, QuizStatus.error);
    expect(h.economy.hearts, 3);

    await h.dispose(tester);
  });
}
