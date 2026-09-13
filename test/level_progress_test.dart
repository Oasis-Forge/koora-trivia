import 'package:flutter_test/flutter_test.dart';
import 'package:football_trivia/domain/entities/category_progress.dart';
import 'package:football_trivia/domain/usecases/evaluate_level.dart';

void main() {
  group('EvaluateLevel', () {
    const useCase = EvaluateLevel();

    test('عشرة من عشرة تمنح ثلاث نجوم', () {
      expect(useCase.stars(correct: 10, total: 10), 3);
    });

    test('تسعة من عشرة تمنح نجمتين', () {
      expect(useCase.stars(correct: 9, total: 10), 2);
    });

    test('سبعة وثمانية تمنحان نجمة واحدة', () {
      expect(useCase.stars(correct: 7, total: 10), 1);
      expect(useCase.stars(correct: 8, total: 10), 1);
    });

    test('أقل من سبعة يعني الرسوب', () {
      expect(useCase.stars(correct: 6, total: 10), 0);
      expect(useCase.passed(correct: 6, total: 10), isFalse);
      expect(useCase.passed(correct: 7, total: 10), isTrue);
    });

    test('لا تقسيم على صفر', () {
      expect(useCase.stars(correct: 0, total: 0), 0);
    });
  });

  group('CategoryProgress', () {
    test('التقدّم الفارغ يفتح المستوى الأول فقط', () {
      final progress = CategoryProgress.empty('world_cup', 10);

      expect(progress.highestUnlockedLevel, 1);
      expect(progress.isUnlocked(1), isTrue);
      expect(progress.isUnlocked(2), isFalse);
      expect(progress.completedLevels, 0);
      expect(progress.totalStars, 0);
    });

    test('اجتياز مستوى يفتح الذي يليه', () {
      final progress = CategoryProgress.empty('world_cup', 10)
          .withLevelStars(1, 2);

      expect(progress.isUnlocked(2), isTrue);
      expect(progress.isUnlocked(3), isFalse);
      expect(progress.completedLevels, 1);
      expect(progress.totalStars, 2);
    });

    test('النجوم لا تتناقص عند إعادة المستوى بنتيجة أسوأ', () {
      final progress = CategoryProgress.empty('world_cup', 10)
          .withLevelStars(1, 3)
          .withLevelStars(1, 1);

      expect(progress.starsFor(1), 3);
    });

    test('النجوم تتحسّن عند إعادة المستوى بنتيجة أفضل', () {
      final progress = CategoryProgress.empty('world_cup', 10)
          .withLevelStars(1, 1)
          .withLevelStars(1, 3);

      expect(progress.starsFor(1), 3);
      expect(progress.totalStars, 3);
    });

    test('الرسوب لا يفتح المستوى التالي', () {
      final progress = CategoryProgress.empty('world_cup', 10)
          .withLevelStars(1, 0);

      expect(progress.isUnlocked(2), isFalse);
      expect(progress.completedLevels, 0);
    });

    test('فجوة في البيانات لا تفتح سلسلة كاملة', () {
      // لو ظهر مستوى مجتاز دون ما قبله، يبقى الفتح عند أول مستوى ناقص.
      final progress = CategoryProgress(
        slug: 'world_cup',
        stars: const [3, 0, 3, 3, 0, 0, 0, 0, 0, 0],
      );

      expect(progress.highestUnlockedLevel, 2);
      expect(progress.isUnlocked(3), isFalse);
    });

    test('إكمال كل المستويات يُعلَن صحيحاً', () {
      final progress = CategoryProgress(
        slug: 'world_cup',
        stars: List<int>.filled(10, 3),
      );

      expect(progress.isFullyCompleted, isTrue);
      expect(progress.highestUnlockedLevel, 10);
      expect(progress.totalStars, 30);
      expect(progress.maxStars, 30);
    });

    test('مستوى خارج النطاق لا يكسر شيئاً', () {
      final progress = CategoryProgress.empty('world_cup', 10);

      expect(progress.starsFor(0), 0);
      expect(progress.starsFor(11), 0);
      expect(progress.withLevelStars(11, 3).totalStars, 0);
    });
  });
}
