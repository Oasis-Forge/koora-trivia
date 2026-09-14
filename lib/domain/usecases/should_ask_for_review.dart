import '../../core/constants/app_config.dart';
import '../entities/quiz_result.dart';

/// هل هذه لحظة مناسبة لطلب تقييم التطبيق؟
///
/// غوغل بلاي يحدّ عدد مرات ظهور نافذة التقييم، فطلبها في لحظة إحباط يهدر فرصة
/// ويجلب تقييماً سيئاً. نطلبها بعد لحظة رضا واضحة فقط، وبفاصل طويل بين كل طلبين.
class ShouldAskForReview {
  const ShouldAskForReview();

  bool call({
    required QuizResult result,
    required int streak,
    required int? levelStars,
    required bool adShown,
    required DateTime? lastAskedAt,
    required DateTime now,
  }) {
    // بعد إعلان يكون اللاعب في أسوأ مزاج لتقييم التطبيق.
    if (adShown) return false;

    if (lastAskedAt != null &&
        now.difference(lastAskedAt) <
            const Duration(days: AppConfig.reviewPromptMinDaysBetween)) {
      return false;
    }

    // تحدي اليوم الثالث على الأقل في سلسلة متصلة: عادة تكوّنت.
    if (result.isDaily) return streak >= AppConfig.reviewPromptMinStreak;

    // ثلاث نجوم فقط — المستوى المجتاز بصعوبة أو الفاشل ليس لحظة رضا.
    if (result.isLevel) return levelStars == 3;

    return false;
  }
}
