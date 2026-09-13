import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/data/datasources/question_local_datasource.dart';
import 'package:football_trivia/data/models/category_model.dart';
import 'package:football_trivia/data/models/question_model.dart';
import 'package:football_trivia/data/repositories/quiz_repository_impl.dart';
import 'package:football_trivia/domain/entities/question.dart';

/// بنك وهمي: تصنيفان × 10 مستويات × 10 أسئلة.
class _FakeDataSource implements QuestionLocalDataSource {
  @override
  Future<QuestionBank> load() async {
    const categories = [
      CategoryModel(slug: 'alpha', name: 'ألفا', idBlock: 1000, order: 1),
      CategoryModel(slug: 'beta', name: 'بيتا', idBlock: 2000, order: 2),
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
