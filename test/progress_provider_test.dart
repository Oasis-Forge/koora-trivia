import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:football_trivia/core/constants/app_config.dart';
import 'package:football_trivia/data/datasources/progress_local_datasource.dart';
import 'package:football_trivia/data/repositories/progress_repository_impl.dart';
import 'package:football_trivia/domain/entities/question.dart';
import 'package:football_trivia/domain/entities/quiz_result.dart';
import 'package:football_trivia/presentation/providers/progress_provider.dart';

/// يغطّي وصل `ProgressProvider` بالتخزين — الطبقة التي لم تكن مغطّاة سابقاً،
/// وهي مسار «اجتياز مستوى ⇒ نجوم ⇒ فتح التالي» الذي يراه اللاعب فعلياً.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// نتيجة مستوى بعدد إجابات صحيحة محدّد من أصل 10.
  QuizResult levelResult({
    required String slug,
    required int level,
    required int correct,
    int total = 10,
  }) {
    final answers = <AnswerRecord>[];
    for (var i = 0; i < total; i++) {
      final q = Question(
        id: 1000 + i,
        category: slug,
        categoryName: 'تصنيف',
        level: level,
        text: 'سؤال $i',
        options: const ['أ', 'ب', 'ج', 'د'],
        answerIndex: 0,
      );
      answers.add(AnswerRecord(
        question: q,
        // الإجابة الصحيحة للأوائل، وخاطئة لما بعدها.
        selectedIndex: i < correct ? 0 : 1,
        earnedPoints: i < correct ? 100 : 0,
        secondsLeft: 10,
      ));
    }
    return QuizResult(
      answers: answers,
      score: correct * 100,
      isDaily: false,
      playedAt: DateTime.now(),
      categorySlug: slug,
      level: level,
    );
  }

  ProgressProvider makeProvider() => ProgressProvider(
        repository: ProgressRepositoryImpl(PrefsProgressDataSource()),
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('اجتياز المستوى الأول يمنح نجوماً ويفتح الثاني', () async {
    final provider = makeProvider();
    await provider.init();

    expect(provider.starsFor('world_cup', 1), 0);
    expect(provider.isUnlocked('world_cup', 2), isFalse,
        reason: 'المستوى الثاني يجب أن يكون مقفلاً قبل اجتياز الأول');

    final outcome = await provider.recordLevelResult(
      levelResult(slug: 'world_cup', level: 1, correct: 7),
    );

    expect(outcome, isNotNull, reason: 'النتيجة من نمط المستويات');
    expect(outcome!.passed, isTrue);
    expect(outcome.stars, greaterThan(0));
    expect(outcome.unlockedNextLevel, isTrue);
    expect(provider.starsFor('world_cup', 1), greaterThan(0));
    expect(provider.isUnlocked('world_cup', 2), isTrue);
  });

  test('النجوم تُحفظ وتبقى بعد إعادة التحميل', () async {
    final first = makeProvider();
    await first.init();
    await first.recordLevelResult(
      levelResult(slug: 'world_cup', level: 1, correct: 10),
    );
    expect(first.starsFor('world_cup', 1), 3);

    // مزوّد جديد يقرأ من التخزين نفسه — يحاكي إعادة تشغيل التطبيق.
    final second = makeProvider();
    await second.init();
    expect(second.starsFor('world_cup', 1), 3,
        reason: 'النجوم يجب أن تنجو من إعادة التشغيل');
    expect(second.isUnlocked('world_cup', 2), isTrue);
  });

  test('الرسوب لا يمنح نجوماً ولا يفتح التالي', () async {
    final provider = makeProvider();
    await provider.init();

    final outcome = await provider.recordLevelResult(
      levelResult(slug: 'world_cup', level: 1, correct: 3),
    );

    expect(outcome!.passed, isFalse);
    expect(outcome.stars, 0);
    expect(provider.isUnlocked('world_cup', 2), isFalse);
  });

  test('نتيجة غير مستوى (لعب سريع) لا تُسجَّل', () async {
    final provider = makeProvider();
    await provider.init();

    final quick = QuizResult(
      answers: const [],
      score: 0,
      isDaily: false,
      playedAt: DateTime.now(),
    );
    expect(await provider.recordLevelResult(quick), isNull);
  });

  test('AppConfig.levelsPerCategory يطابق طول تقدّم التصنيف', () async {
    final provider = makeProvider();
    await provider.init();
    expect(provider.forCategory('world_cup').levelCount,
        AppConfig.levelsPerCategory);
  });
}
