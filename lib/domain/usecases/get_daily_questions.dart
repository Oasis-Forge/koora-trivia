import '../../core/constants/app_config.dart';
import '../../core/utils/day_key.dart';
import '../entities/question.dart';
import '../repositories/quiz_repository.dart';

/// تحضير أسئلة تحدي اليوم — نفس الأسئلة لكل مستخدم في نفس اليوم.
class GetDailyQuestions {
  const GetDailyQuestions(this._repository);

  final QuizRepository _repository;

  Future<List<Question>> call({String? dayKey}) {
    return _repository.getDailyQuestions(
      dayKey: dayKey ?? DayKey.today(),
      count: AppConfig.dailyQuestionCount,
    );
  }
}
