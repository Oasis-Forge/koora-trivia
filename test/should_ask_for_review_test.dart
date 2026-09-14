import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/domain/usecases/should_ask_for_review.dart';

final _now = DateTime(2026, 9, 14, 20);

QuizResult _round({bool daily = false, bool level = false}) => QuizResult(
      answers: const [],
      score: 0,
      isDaily: daily,
      playedAt: _now,
      categorySlug: level ? 'world_cup' : null,
      level: level ? 3 : null,
    );

bool _ask({
  required QuizResult result,
  int streak = 0,
  int? stars,
  bool adShown = false,
  DateTime? lastAskedAt,
}) =>
    const ShouldAskForReview()(
      result: result,
      streak: streak,
      levelStars: stars,
      adShown: adShown,
      lastAskedAt: lastAskedAt,
      now: _now,
    );

void main() {
  const minStreak = AppConfig.reviewPromptMinStreak;

  test('تحدي اليوم يُطلب التقييم عنده بسلسلة كافية فقط', () {
    expect(_ask(result: _round(daily: true), streak: minStreak), isTrue);
    expect(_ask(result: _round(daily: true), streak: minStreak + 5), isTrue);
    expect(_ask(result: _round(daily: true), streak: minStreak - 1), isFalse);
  });

  test('المستوى يُطلب التقييم عنده بثلاث نجوم فقط', () {
    expect(_ask(result: _round(level: true), stars: 3), isTrue);
    expect(_ask(result: _round(level: true), stars: 2), isFalse);
    expect(_ask(result: _round(level: true), stars: 1), isFalse);
    // مستوى فاشل.
    expect(_ask(result: _round(level: true), stars: 0), isFalse);
    expect(_ask(result: _round(level: true)), isFalse);
  });

  test('اللعب السريع لا يُطلب التقييم بعده', () {
    expect(_ask(result: _round(), streak: 10, stars: 3), isFalse);
  });

  test('لا طلب بعد إعلان مهما كانت الجولة', () {
    expect(
      _ask(result: _round(level: true), stars: 3, adShown: true),
      isFalse,
    );
    expect(
      _ask(result: _round(daily: true), streak: minStreak, adShown: true),
      isFalse,
    );
  });

  test('طلبان بينهما أقل من المدة المحددة لا يُسمح بهما', () {
    const days = AppConfig.reviewPromptMinDaysBetween;
    DateTime ago(Duration d) => _now.subtract(d);

    expect(
      _ask(
        result: _round(level: true),
        stars: 3,
        lastAskedAt: ago(const Duration(days: days - 1)),
      ),
      isFalse,
    );
    expect(
      _ask(
        result: _round(level: true),
        stars: 3,
        lastAskedAt: ago(const Duration(days: days)),
      ),
      isTrue,
    );
  });
}
