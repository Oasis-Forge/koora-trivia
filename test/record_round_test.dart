import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/domain/entities/daily_task.dart';
import 'package:football_trivia/domain/entities/economy.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/domain/entities/user_stats.dart';
import 'package:football_trivia/presentation/providers/economy_provider.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';
import 'package:football_trivia/presentation/providers/record_round.dart';
import 'package:football_trivia/presentation/providers/stats_provider.dart';

import 'fakes/fake_repositories.dart';

/// إحصائيات يتعطّل حفظها.
class _BrokenStatsRepository extends FakeStatsRepository {
  @override
  Future<void> save(UserStats value) async => throw StateError('تعذّر الحفظ');
}

/// جولة من عشرة أسئلة: أول [correct] صحيحة والباقي خاطئ.
QuizResult _result({required int correct, bool daily = false}) {
  final questions = fakeQuestions(AppConfig.questionsPerLevel);
  return QuizResult(
    answers: [
      for (var i = 0; i < questions.length; i++)
        AnswerRecord(
          question: questions[i],
          selectedIndex: i < correct ? 0 : 1,
          earnedPoints: i < correct ? 100 : 0,
          secondsLeft: 10,
        ),
    ],
    score: correct * 100,
    isDaily: daily,
    playedAt: DateTime.now(),
    categorySlug: daily ? null : 'alpha',
    level: daily ? null : 1,
    dailyDayKey: daily ? DayKey.today() : null,
  );
}

late StatsProvider stats;
late EconomyProvider economy;
late ProgressProvider progress;
late RecordRound record;

Future<void> _setUp({required int hearts, bool brokenStats = false}) async {
  stats = StatsProvider(
    repository: brokenStats ? _BrokenStatsRepository() : FakeStatsRepository(),
  );
  economy = EconomyProvider(
    repository: FakeEconomyRepository(
      Economy(hearts: hearts, lastRegenAtIso: DateTime.now().toIso8601String()),
    ),
  );
  progress = ProgressProvider(repository: FakeProgressRepository());
  await Future.wait([stats.init(), economy.init(), progress.init()]);
  record = RecordRound(stats: stats, economy: economy, progress: progress);
}

int _task(TaskKind kind) =>
    economy.tasks.firstWhere((t) => t.kind == kind).progress;

void main() {
  test('اجتياز مستوى: يعيد قلب المحاولة ويحفظ النجوم والمهمة والإحصائيات',
      () async {
    await _setUp(hearts: 4);

    final round = await record(_result(correct: 10));

    expect(round.lostHeart, isFalse);
    expect(round.level!.passed, isTrue);
    expect(economy.hearts, 5);
    expect(progress.forCategory('alpha').starsFor(1), 3);
    expect(_task(TaskKind.completeLevel), 1);
    expect(stats.stats.gamesPlayed, 1);
  });

  test('إخفاق في مستوى: القلب لا يعود ولا نجوم ولا مهمة', () async {
    await _setUp(hearts: 4);

    final round = await record(_result(correct: 3));

    expect(round.lostHeart, isTrue);
    expect(round.level!.passed, isFalse);
    expect(economy.hearts, 4);
    expect(progress.forCategory('alpha').starsFor(1), 0);
    expect(_task(TaskKind.completeLevel), 0);
  });

  test('تحدي اليوم: القلب والسلسلة مرة واحدة مهما تكرّر حفظ النتيجة', () async {
    await _setUp(hearts: 3);
    final result = _result(correct: 5, daily: true);

    final first = await record(result);
    expect(first.earnedHeart, isTrue);
    expect(first.level, isNull);
    expect(economy.hearts, 4);
    expect(stats.streak, 1);
    expect(_task(TaskKind.completeDaily), 1);

    final second = await record(result);
    expect(second.earnedHeart, isFalse);
    expect(economy.hearts, 4);
    expect(stats.streak, 1);
  });

  test('فشل خطوة يُسجَّل في سجل الأخطاء ولا يمنع بقية الحفظ', () async {
    final reported = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = original);

    await _setUp(hearts: 4, brokenStats: true);
    final round = await record(_result(correct: 10));

    expect(reported, hasLength(1));
    expect(reported.single.library, 'record_round');
    expect(economy.hearts, 5);
    expect(round.level!.passed, isTrue);
    expect(progress.forCategory('alpha').starsFor(1), 3);
  });
}
