import '../../core/constants/app_strings.dart';
import 'question.dart';

/// إجابة واحدة داخل الجولة.
class AnswerRecord {
  const AnswerRecord({
    required this.question,
    required this.selectedIndex,
    required this.earnedPoints,
    required this.secondsLeft,
    this.skipped = false,
  });

  /// -1 يعني أن الوقت انتهى أو أن اللاعب تخطّى السؤال.
  final Question question;
  final int selectedIndex;
  final int earnedPoints;
  final int secondsLeft;

  /// تخطٍّ مقصود بمساعدة، لا انتهاء وقت.
  final bool skipped;

  bool get isCorrect => question.isCorrect(selectedIndex);
  bool get timedOut => selectedIndex < 0 && !skipped;
}

class QuizResult {
  const QuizResult({
    required this.answers,
    required this.score,
    required this.isDaily,
    required this.playedAt,
    this.categorySlug,
    this.level,
    this.dailyDayKey,
  });

  final List<AnswerRecord> answers;
  final int score;
  final bool isDaily;
  final DateTime playedAt;

  /// التصنيف والمستوى — يُملآن في نمط المستويات فقط.
  final String? categorySlug;
  final int? level;

  /// يوم تحدي اليوم الذي بدأه اللاعب (`yyyy-MM-dd`) — قد يسبق يوم انتهاء الجولة.
  final String? dailyDayKey;

  bool get isLevel => categorySlug != null && level != null;

  int get total => answers.length;
  int get correctCount => answers.where((a) => a.isCorrect).length;

  double get accuracy => total == 0 ? 0 : correctCount / total;
  int get accuracyPercent => (accuracy * 100).round();

  String get rankLabel {
    if (accuracy >= 0.9) return AppStrings.rankLegend;
    if (accuracy >= 0.7) return AppStrings.rankPro;
    if (accuracy >= 0.5) return AppStrings.rankGood;
    return AppStrings.rankRookie;
  }
}
