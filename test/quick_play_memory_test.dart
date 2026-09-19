import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/data/datasources/question_local_datasource.dart';
import 'package:football_trivia/data/models/category_model.dart';
import 'package:football_trivia/data/models/question_model.dart';
import 'package:football_trivia/data/repositories/quiz_repository_impl.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/repositories/recent_questions_repository.dart';
import 'package:football_trivia/domain/usecases/get_quiz_questions.dart';

import 'fakes/fake_repositories.dart';

class _MemoryRecent implements RecentQuestionsRepository {
  List<int> ids = [];

  @override
  Future<List<int>> load() async => List.of(ids);

  @override
  Future<void> save(List<int> value) async => ids = List.of(value);
}

/// عشرة تصنيفات × 10 مستويات × 10 أسئلة، كالبنك الحقيقي.
class _Bank implements QuestionLocalDataSource {
  @override
  Future<QuestionBank> load() async {
    final categories = [
      for (var c = 1; c <= 10; c++)
        CategoryModel(slug: 'c$c', name: 'ت$c', idBlock: c * 1000, order: c),
    ];
    return QuestionBank(
      categories: categories,
      questions: [
        for (final c in categories)
          for (var i = 1; i <= 100; i++)
            QuestionModel(
              id: c.idBlock + i,
              category: c.slug,
              categoryName: c.name,
              level: ((i - 1) ~/ 10) + 1,
              text: 'س ${c.idBlock + i}',
              options: const ['أ', 'ب', 'ج', 'د'],
              answerIndex: 0,
            ),
      ],
    );
  }
}

void main() {
  late _MemoryRecent recent;
  late FakeProgressRepository progress;
  late GetQuizQuestions quickPlay;

  setUp(() {
    recent = _MemoryRecent();
    progress = FakeProgressRepository();
    quickPlay = GetQuizQuestions(
      QuizRepositoryImpl(_Bank()),
      recent: recent,
      progress: progress,
    );
  });

  group('ذاكرة الجولة السريعة', () {
    test('جولتان متتاليتان لا تتشاركان سؤالاً', () async {
      final first = (await quickPlay()).map((q) => q.id).toSet();
      final second = (await quickPlay()).map((q) => q.id).toSet();

      expect(first.intersection(second), isEmpty);
      expect(recent.ids, hasLength(2 * AppConfig.quickPlayQuestionCount));
    });

    test('الذاكرة لا تتجاوز سقفها، والأقدم يخرج أولاً', () async {
      for (var round = 0; round < 20; round++) {
        await quickPlay();
      }
      expect(recent.ids, hasLength(AppConfig.quickPlayRecentMemory));
    });

    test('لاعب جديد يلقى أسئلة المستوى الأول', () async {
      // لا تقدّم محفوظ: المستوى الأول وحده مفتوح في كل تصنيف.
      final questions = await quickPlay();
      expect(questions.every((q) => q.level == 1), isTrue);
    });

    test('المستويات التي فتحها اللاعب تدخل الجولة', () async {
      // اجتاز أول أربعة مستويات في c1، فالخامس مفتوح له هناك.
      progress.data = {
        'c1': const CategoryProgress(slug: 'c1', stars: [3, 3, 2, 1, 0, 0, 0, 0, 0, 0]),
      };

      final questions = await quickPlay(categorySlug: 'c1');

      expect(questions.every((q) => q.level <= 5), isTrue);
    });
  });
}
