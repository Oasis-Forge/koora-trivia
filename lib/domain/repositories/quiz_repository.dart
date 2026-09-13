import '../entities/category.dart';
import '../entities/question.dart';

abstract class QuizRepository {
  /// كل التصنيفات المتاحة مرتّبة.
  Future<List<Category>> getCategories();

  /// أسئلة مستوى واحد داخل تصنيف (10 أسئلة)، بترتيب ثابت.
  Future<List<Question>> getLevelQuestions({
    required String categorySlug,
    required int level,
  });

  /// عدد المستويات المتاحة فعلياً في تصنيف.
  Future<int> getLevelCount(String categorySlug);

  /// جولة سريعة عشوائية، مع إمكانية تحديد تصنيف.
  Future<List<Question>> getRandomQuestions({
    required int count,
    String? categorySlug,
  });

  /// أسئلة تحدي اليوم — ثابتة لكل يوم بفضل البذرة المشتقة من التاريخ.
  Future<List<Question>> getDailyQuestions({
    required String dayKey,
    required int count,
  });
}
