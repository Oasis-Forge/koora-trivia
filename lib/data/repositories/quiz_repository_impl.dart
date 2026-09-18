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
    Set<int> avoid = const {},
    bool Function(Question question)? prefer,
  }) async {
    final pool = await _pool(categorySlug);
    if (pool.isEmpty) return const [];

    final shuffled = List<Question>.of(pool)..shuffle(_random);
    final fresh = [for (final q in shuffled) if (!avoid.contains(q.id)) q];
    // المرئية مؤخراً آخر الطبقات، والأقدم رؤيةً قبل الأحدث.
    final order = {for (final (i, id) in avoid.indexed) id: i};
    final seen = [for (final q in shuffled) if (avoid.contains(q.id)) q]
      ..sort((a, b) => order[a.id]!.compareTo(order[b.id]!));

    final picked = [
      if (prefer != null) ...[
        ...fresh.where(prefer),
        ...fresh.where((q) => !prefer(q)),
      ] else
        ...fresh,
      ...seen,
    ].take(min(count, pool.length)).toList();

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
    final wanted = min(count, bank.questions.length);
    if (wanted <= 0) return const [];

    // مجموعة لكل صعوبة مرتّبة بالمعرّف: نفس الأسئلة للجميع وبكل لغة.
    final pools = {
      for (final d in Difficulty.values)
        d: bank.questions.where((q) => q.difficulty == d).toList()
          ..sort((a, b) => a.id.compareTo(b.id)),
    };
    final mix = _dailyMix(wanted, pools);

    // الدورة = الأيام التي تكفيها أضيق مجموعة. كل مجموعة تُخلط مرة واحدة للدورة
    // ويأخذ كل يوم شريحته التالية منها، فلا يتكرر سؤال حتى تبدأ دورة جديدة.
    final cycleDays = [
      for (final d in Difficulty.values)
        if (mix[d]! > 0) pools[d]!.length ~/ mix[d]!,
    ].reduce(min);
    final day = DayKey.epochDay(dayKey);
    final dayInCycle = day % cycleDays;
    final cycle = (day - dayInCycle) ~/ cycleDays;

    // من الأسهل إلى الأصعب، كما تتدرّج المستويات.
    final picked = [
      for (final d in Difficulty.values)
        ...SeededRandom(cycle * Difficulty.values.length + d.index)
            .shuffled(pools[d]!)
            .skip(dayInCycle * mix[d]!)
            .take(mix[d]!),
    ];

    return [
      for (final q in picked)
        q.withOptionsOrder(SeededRandom(day + q.id).shuffled(q.options)),
    ];
  }

  /// يوزّع [count] على الصعوبات بنسبة حجم كل مجموعة، والباقي للأكبر كسراً:
  /// سبعة أسئلة من بنك 3 مستويات سهلة و4 متوسطة و3 صعبة = 2 و3 و2.
  static Map<Difficulty, int> _dailyMix(
    int count,
    Map<Difficulty, List<Question>> pools,
  ) {
    final total = pools.values.fold<int>(0, (sum, p) => sum + p.length);
    final mix = {
      for (final d in Difficulty.values) d: count * pools[d]!.length ~/ total,
    };
    final left = count - mix.values.fold<int>(0, (sum, n) => sum + n);
    int remainder(Difficulty d) => count * pools[d]!.length % total;
    final byRemainder = [...Difficulty.values]..sort(
        (a, b) => remainder(b) != remainder(a)
            ? remainder(b).compareTo(remainder(a))
            : a.index.compareTo(b.index),
      );
    for (final d in byRemainder.take(left)) {
      mix[d] = mix[d]! + 1;
    }
    return mix;
  }

  Future<List<Question>> _pool(String? categorySlug) async {
    final bank = await _dataSource.load();
    if (categorySlug == null) return bank.questions;

    final filtered =
        bank.questions.where((q) => q.category == categorySlug).toList();
    return filtered.isEmpty ? bank.questions : filtered;
  }
}
