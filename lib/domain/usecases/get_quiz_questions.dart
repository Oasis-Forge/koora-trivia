import '../../core/constants/app_config.dart';
import '../entities/question.dart';
import '../repositories/progress_repository.dart';
import '../repositories/quiz_repository.dart';
import '../repositories/recent_questions_repository.dart';

/// تحضير أسئلة جولة سريعة: تتجنّب ما رآه اللاعب مؤخراً، وتفضّل المستويات
/// المفتوحة له.
///
/// المفتوحة أولاً لسببين: لاعب جديد لا يُرمى في أسئلة المستوى العاشر، والجولة
/// السريعة لا تحرق أسئلة مستويات لم يصلها بعد فيلقاها لاحقاً وهو يعرف جوابها.
class GetQuizQuestions {
  const GetQuizQuestions(
    this._repository, {
    RecentQuestionsRepository? recent,
    ProgressRepository? progress,
  })  : _recent = recent,
        _progress = progress;

  final QuizRepository _repository;
  final RecentQuestionsRepository? _recent;
  final ProgressRepository? _progress;

  Future<List<Question>> call({
    String? categorySlug,
    int count = AppConfig.quickPlayQuestionCount,
  }) async {
    final recent = await _recent?.load() ?? const <int>[];
    final progress = await _progress?.loadAll();

    final questions = await _repository.getRandomQuestions(
      count: count,
      categorySlug: categorySlug,
      avoid: {...recent},
      // تصنيف بلا تقدّم محفوظ مفتوحٌ مستواه الأول وحده.
      prefer: progress == null
          ? null
          : (q) => progress[q.category]?.isUnlocked(q.level) ?? q.level == 1,
    );

    final recentSaver = _recent;
    if (recentSaver != null) {
      final ids = questions.map((q) => q.id).toSet();
      final updated = [
        for (final id in recent)
          if (!ids.contains(id)) id,
        ...ids,
      ];
      final keep = updated.length - AppConfig.quickPlayRecentMemory;
      await recentSaver.save(keep > 0 ? updated.sublist(keep) : updated);
    }
    return questions;
  }
}
