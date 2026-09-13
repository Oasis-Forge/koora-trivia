import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

/// تحضير أسئلة مستوى واحد داخل تصنيف.
class GetLevelQuestions {
  const GetLevelQuestions(this._repository);

  final QuizRepository _repository;

  Future<List<Question>> call({
    required String categorySlug,
    required int level,
  }) {
    return _repository.getLevelQuestions(
      categorySlug: categorySlug,
      level: level,
    );
  }
}
