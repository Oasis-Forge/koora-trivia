import '../../core/constants/app_config.dart';
import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

/// تحضير أسئلة جولة سريعة.
class GetQuizQuestions {
  const GetQuizQuestions(this._repository);

  final QuizRepository _repository;

  Future<List<Question>> call({
    String? categorySlug,
    int count = AppConfig.quickPlayQuestionCount,
  }) {
    return _repository.getRandomQuestions(
      count: count,
      categorySlug: categorySlug,
    );
  }
}
