import 'dart:math';

import '../../core/utils/day_key.dart';
import '../../core/utils/seeded_random.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/question_local_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._dataSource);

  final QuestionLocalDataSource _dataSource;
  final Random _random = Random();

  @override
  Future<List<Category>> getCategories() async =>
      (await _dataSource.load()).categories;

  @override
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  }) async {
    final bank = await _dataSource.load();
    final questions = bank.questions
        .where((q) => q.category == categorySlug && q.level == level)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    // الخيارات تُخلط ببذرة مشتقة من المعرّف: ترتيب ثابت لنفس السؤال دائماً،
    // فلا يتغيّر موضع الإجابة بين محاولة وأخرى في نفس المستوى.
    return [
      for (final q in questions)
        q.withOptionsOrder(SeededRandom(q.id).shuffled(q.options)),
    ];
  }

  @override
  Future<int> getLevelCount(String categorySlug) async {
    final bank = await _dataSource.load();
    final levels = bank.questions
        .where((q) => q.category == categorySlug)
        .map((q) => q.level)
        .toSet();
    return levels.isEmpty ? 0 : levels.reduce(max);
  }

  @override
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  }) async {
    final pool = await _pool(categorySlug);
    if (pool.isEmpty) return const [];

    final picked = (List<Question>.of(pool)..shuffle(_random))
        .take(min(count, pool.length))
        .toList();

    return [
      for (final q in picked)
        q.withOptionsOrder(List<String>.of(q.options)..shuffle(_random)),
    ];
  }

  @override
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  }) async {
    final bank = await _dataSource.load();
    if (bank.questions.isEmpty) return const [];

    // ترتيب ثابت (حسب المعرّف) ثم خلط ببذرة اليوم = نفس الأسئلة للجميع.
    final ordered = List<Question>.of(bank.questions)
      ..sort((a, b) => a.id.compareTo(b.id));

    final seed = DayKey.epochDay(dayKey);
    final picked = SeededRandom(seed).shuffled(ordered).take(
          min(count, ordered.length),
        );

    return [
      for (final q in picked)
        q.withOptionsOrder(SeededRandom(seed + q.id).shuffled(q.options)),
    ];
  }

  Future<List<Question>> _pool(String? categorySlug) async {
    final bank = await _dataSource.load();
    if (categorySlug == null) return bank.questions;

    final filtered =
        bank.questions.where((q) => q.category == categorySlug).toList();
    return filtered.isEmpty ? bank.questions : filtered;
  }
}
