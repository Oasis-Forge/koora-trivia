// `Category` تتعارض مع التعليق التوضيحي بنفس الاسم في foundation.
import 'package:flutter/foundation.dart' hide Category;

import '../../core/constants/app_config.dart';
import '../../domain/entities/category_progress.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/usecases/evaluate_level.dart';

/// نتيجة تسجيل مستوى — تحتاجها شاشة النتيجة لعرض النجوم وحالة الفتح.
class LevelOutcome {
  const LevelOutcome({
    required this.stars,
    required this.passed,
    required this.isNewBest,
    required this.unlockedNextLevel,
  });

  final int stars;
  final bool passed;

  /// هل تحسّن التقييم عن المحاولة السابقة؟
  final bool isNewBest;

  /// هل فُتح مستوى جديد بهذه المحاولة؟
  final bool unlockedNextLevel;
}

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({
    required ProgressRepository repository,
    EvaluateLevel evaluateLevel = const EvaluateLevel(),
  })  : _repository = repository,
        _evaluateLevel = evaluateLevel;

  final ProgressRepository _repository;
  final EvaluateLevel _evaluateLevel;

  Map<String, CategoryProgress> _progress = {};
  bool _loading = true;

  bool get isLoading => _loading;

  int get levelCount => AppConfig.levelsPerCategory;

  Future<void> init() async {
    _progress = await _repository.loadAll();
    _loading = false;
    notifyListeners();
  }

  /// تقدّم تصنيف — يعيد تقدّماً فارغاً إن لم يُلعب بعد.
  CategoryProgress forCategory(String slug) =>
      _progress[slug] ?? CategoryProgress.empty(slug, levelCount);

  bool isUnlocked(String slug, int level) =>
      forCategory(slug).isUnlocked(level);

  int starsFor(String slug, int level) => forCategory(slug).starsFor(level);

  /// مجموع النجوم في كل التصنيفات.
  int get totalStars =>
      _progress.values.fold(0, (sum, p) => sum + p.totalStars);

  /// مجموع المستويات المجتازة في كل التصنيفات.
  int get totalCompletedLevels =>
      _progress.values.fold(0, (sum, p) => sum + p.completedLevels);

  /// هل يوجد تقدّم محفوظ أصلاً؟ يُستخدم لتعطيل زر التصفير.
  bool get hasProgress => totalCompletedLevels > 0;

  /// تسجيل نتيجة مستوى منتهٍ.
  ///
  /// يعيد `null` إذا لم تكن النتيجة من نمط المستويات.
  Future<LevelOutcome?> recordLevelResult(QuizResult result) async {
    final slug = result.categorySlug;
    final level = result.level;
    if (slug == null || level == null) return null;

    final earned = _evaluateLevel.stars(
      correct: result.correctCount,
      total: result.total,
    );

    final before = forCategory(slug);
    final previousUnlocked = before.highestUnlockedLevel;
    final isNewBest = earned > before.starsFor(level);

    final after = before.withLevelStars(level, earned);
    _progress[slug] = after;
    notifyListeners();

    if (isNewBest) await _repository.save(after);

    return LevelOutcome(
      stars: earned,
      passed: earned > 0,
      isNewBest: isNewBest,
      unlockedNextLevel: after.highestUnlockedLevel > previousUnlocked,
    );
  }

  Future<void> resetAll() async {
    _progress = {};
    notifyListeners();
    await _repository.clear();
  }
}
