import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/utils/day_key.dart';
import 'package:football_trivia/core/utils/seeded_random.dart';
import 'package:football_trivia/data/datasources/question_local_datasource.dart';
import 'package:football_trivia/data/models/category_model.dart';
import 'package:football_trivia/data/models/question_model.dart';
import 'package:football_trivia/data/repositories/quiz_repository_impl.dart';
import 'package:football_trivia/domain/entities/question.dart';

/// بنك وهمي: عدد من التصنيفات × 10 مستويات × 10 أسئلة.
/// الافتراضي تصنيفان؛ اختبارات تحدي اليوم تستخدم عشرة ليطابق حجم البنك الحقيقي.
class _FakeDataSource implements QuestionLocalDataSource {
  _FakeDataSource({this.categoryCount = 2});

  final int categoryCount;

  @override
  Future<QuestionBank> load() async {
    final categories = [
      for (var c = 1; c <= categoryCount; c++)
        CategoryModel(
          slug: switch (c) { 1 => 'alpha', 2 => 'beta', _ => 'cat$c' },
          name: switch (c) { 1 => 'ألفا', 2 => 'بيتا', _ => 'تصنيف $c' },
          idBlock: c * 1000,
          order: c,
        ),
    ];

    final questions = <QuestionModel>[];
    for (final c in categories) {
      for (var i = 1; i <= 100; i++) {
        questions.add(
          QuestionModel(
            id: c.idBlock + i,
            category: c.slug,
            categoryName: c.name,
            level: ((i - 1) ~/ 10) + 1,
            text: 'سؤال ${c.slug} رقم $i',
            options: ['خيار$i-أ', 'خيار$i-ب', 'خيار$i-ج', 'خيار$i-د'],
            answerIndex: i % 4,
          ),
        );
      }
    }

    return QuestionBank(categories: categories, questions: questions);
  }
}

void main() {
  late QuizRepositoryImpl repository;

  setUp(() => repository = QuizRepositoryImpl(_FakeDataSource()));

  test('المستوى يعيد 10 أسئلة من التصنيف الصحيح', () async {
    final questions = await repository.getLevelQuestions(
      categorySlug: 'alpha',
      level: 3,
    );

    expect(questions.length, 10);
    expect(questions.every((q) => q.category == 'alpha'), isTrue);
    expect(questions.every((q) => q.level == 3), isTrue);
    expect(questions.map((q) => q.id), [1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030]);
  });

  test('ترتيب خيارات المستوى ثابت بين المحاولات', () async {
    final first =
        await repository.getLevelQuestions(categorySlug: 'beta', level: 5);
    final second =
        await repository.getLevelQuestions(categorySlug: 'beta', level: 5);

    expect(first.first.options, second.first.options);
    expect(first.first.answerIndex, second.first.answerIndex);
  });

  test('الصعوبة مشتقة من المستوى', () async {
    final easy =
        await repository.getLevelQuestions(categorySlug: 'alpha', level: 2);
    final medium =
        await repository.getLevelQuestions(categorySlug: 'alpha', level: 6);
    final hard =
        await repository.getLevelQuestions(categorySlug: 'alpha', level: 9);

    expect(easy.first.difficulty, Difficulty.easy);
    expect(medium.first.difficulty, Difficulty.medium);
    expect(hard.first.difficulty, Difficulty.hard);
  });

  test('عدد المستويات يساوي 10', () async {
    expect(await repository.getLevelCount('alpha'), 10);
  });

  test('تحدي اليوم ثابت لنفس التاريخ ومختلف بين يومين', () async {
    final a = await repository.getDailyQuestions(dayKey: '2026-08-03', count: 7);
    final b = await repository.getDailyQuestions(dayKey: '2026-08-03', count: 7);
    final c = await repository.getDailyQuestions(dayKey: '2026-08-04', count: 7);

    expect(a.map((q) => q.id), b.map((q) => q.id));
    expect(a.first.options, b.first.options);
    expect(a.map((q) => q.id).toList(), isNot(equals(c.map((q) => q.id).toList())));
  });

  test('تحدي اليوم لا يكرر أسئلة الأمس طوال سنة كاملة', () async {
    // كانت البذرة تُفرض فردية، فيتطابق كل يوم زوجي مع اليوم الفردي الذي يليه
    // ويحصل اللاعب على أسئلة الأمس نفسها. مقارنة يومين فقط لم تكشف ذلك.
    final bank = QuizRepositoryImpl(_FakeDataSource(categoryCount: 10));
    List<int>? previous;

    for (var i = 0; i < 366; i++) {
      final dayKey = DayKey.from(DateTime.utc(2026, 1, 1).add(Duration(days: i)));
      final ids = (await bank.getDailyQuestions(dayKey: dayKey, count: 7))
          .map((q) => q.id)
          .toList();

      if (previous != null) {
        final shared = ids.where(previous.contains).length;
        expect(
          shared,
          lessThanOrEqualTo(2),
          reason: '$dayKey يشارك $shared أسئلة مع اليوم السابق',
        );
      }
      previous = ids;
    }
  });

  test('تحدي اليوم: سؤالان سهلان ثم ثلاثة متوسطة ثم سؤالان صعبان', () async {
    final bank = QuizRepositoryImpl(_FakeDataSource(categoryCount: 10));

    for (final dayKey in ['2026-09-15', '2027-02-01']) {
      final questions = await bank.getDailyQuestions(dayKey: dayKey, count: 7);
      expect(
        questions.map((q) => q.difficulty),
        [
          Difficulty.easy,
          Difficulty.easy,
          Difficulty.medium,
          Difficulty.medium,
          Difficulty.medium,
          Difficulty.hard,
          Difficulty.hard,
        ],
        reason: dayKey,
      );
    }
  });

  test('لا يتكرر سؤال في تحدي اليوم طوال الدورة', () async {
    // بحجم البنك الحقيقي: 300 سهل و400 متوسط و300 صعب، فالدورة 133 يوماً
    // (400 ÷ 3). اليوم 20748 = 156 × 133 أول أيام دورة (22 أكتوبر 2026).
    final bank = QuizRepositoryImpl(_FakeDataSource(categoryCount: 10));
    const cycleDays = 133;
    const firstDay = 156 * cycleDays;
    final seen = <int>{};

    for (var i = 0; i < cycleDays; i++) {
      final dayKey =
          DayKey.from(DateTime.utc(1970).add(Duration(days: firstDay + i)));
      final questions = await bank.getDailyQuestions(dayKey: dayKey, count: 7);
      for (final q in questions) {
        expect(seen.add(q.id), isTrue, reason: 'السؤال ${q.id} تكرر في $dayKey');
      }
    }
    expect(seen, hasLength(cycleDays * 7));
  });

  test('رقم اليوم لا يتأثر بالمنطقة الزمنية للجهاز', () {
    // كان التاريخ المحلي يُطرح من منتصف ليل UTC، فيتأخر الرقم يوماً شرق غرينتش
    // ويحصل الخليج وأوروبا على تحدٍّ مختلف في نفس التاريخ.
    expect(DayKey.epochDay('1970-01-02'), 1);
    expect(DayKey.epochDay('2026-09-13'), 20709);
  });

  test('بذرتان متجاورتان لا تعطيان نفس الخلط', () {
    final items = List<int>.generate(50, (i) => i);
    for (var seed = 20000; seed < 20200; seed += 2) {
      expect(
        SeededRandom(seed).shuffled(items),
        isNot(equals(SeededRandom(seed + 1).shuffled(items))),
        reason: 'البذرتان $seed و${seed + 1}',
      );
    }
  });

  test('خلط الخيارات يحافظ على الإجابة الصحيحة', () async {
    final questions =
        await repository.getDailyQuestions(dayKey: '2026-08-03', count: 7);

    for (final q in questions) {
      expect(q.options.length, 4);
      expect(q.options.contains(q.correctAnswer), isTrue);
    }
  });

  test('التصفية حسب التصنيف تعيد أسئلة ذلك التصنيف فقط', () async {
    final questions =
        await repository.getRandomQuestions(count: 5, categorySlug: 'beta');
    expect(questions.every((q) => q.category == 'beta'), isTrue);
  });

  test('طلب أسئلة أكثر من المتاح لا يفشل', () async {
    final questions = await repository.getRandomQuestions(count: 9999);
    expect(questions.length, 200);
  });
}
