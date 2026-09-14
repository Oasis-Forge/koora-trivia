import '../../core/constants/app_config.dart';

/// تقييم نتيجة مستوى: كم نجمة استحقّها اللاعب وهل اجتاز المستوى.
class EvaluateLevel {
  const EvaluateLevel();

  /// يعيد عدد النجوم من 0 إلى 3. الصفر يعني الرسوب.
  int stars({required int correct, required int total}) {
    if (total <= 0) return 0;
    final ratio = correct / total;

    if (ratio >= AppConfig.threeStarRatio) return 3;
    if (ratio >= AppConfig.twoStarRatio) return 2;
    if (ratio >= AppConfig.passRatio) return 1;
    return 0;
  }

  bool passed({required int correct, required int total}) =>
      stars(correct: correct, total: total) > 0;

  /// أقل عدد إجابات صحيحة من [total] يمنح [starCount] نجوم. يُحسب من `stars`
  /// نفسها حتى لا تختلف العتبة المعروضة عن المطبّقة (0.7 × 10 عشرياً ليست 7).
  int minCorrectFor(int starCount, {required int total}) {
    for (var correct = 0; correct <= total; correct++) {
      if (stars(correct: correct, total: total) >= starCount) return correct;
    }
    return total;
  }
}
