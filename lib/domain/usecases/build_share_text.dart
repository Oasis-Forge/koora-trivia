import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/arabic_count.dart';
import '../../core/utils/day_key.dart';
import '../entities/quiz_result.dart';

/// يبني نص المشاركة على هيئة شبكة مربّعات قابلة للمقارنة بلمحة.
///
/// النمط مستوحى من Wordle: سطر واحد بصري يمكن لصقه في مجموعة واتساب ومقارنته
/// فوراً بنتيجة الآخرين. **لا يكشف أي إجابة** — يعرض نمط الصح والخطأ فقط،
/// فيمكن مشاركته قبل أن يلعب الأصدقاء.
///
/// هذا النص هو سطح المنافسة الوحيد في التطبيق بعد قرار الاكتفاء بالتخزين
/// المحلي، وهو أيضاً قناة النمو العضوي الأساسية.
class BuildShareText {
  const BuildShareText();

  static const String correctSquare = '🟩';
  static const String wrongSquare = '🟥';
  static const String missedSquare = '⬜';

  String call(QuizResult result, {required int streak, String? categoryName}) {
    final buffer = StringBuffer();

    // العنوان: التحدي اليومي يحمل تاريخه لأن أسئلته واحدة لكل اللاعبين.
    if (result.isDaily) {
      buffer.writeln(
        '⚽ ${AppStrings.appName} · ${DayKey.arabicShortDate(result.playedAt)}',
      );
    } else if (result.isLevel && categoryName != null) {
      buffer.writeln('⚽ ${AppStrings.appName}');
      buffer.writeln('🏆 $categoryName · ${AppStrings.level} ${result.level}');
    } else {
      buffer.writeln('⚽ ${AppStrings.appName}');
      buffer.writeln('🎯 ${AppStrings.quickRound}');
    }

    buffer.writeln('${grid(result)}  ${result.correctCount}/${result.total}');

    if (streak > 0) {
      // بعد نقطتين يأتي العدد مرفوعاً: «يومان» · «5 أيام» · «12 يوماً».
      buffer.writeln(
        '🔥 ${AppStrings.streakLabel}: '
        '${ArabicCount.format(streak, ArabicNoun.day)}',
      );
    }

    // الرابط في سطر وحده: تطبيقات المحادثة تحوّله إلى معاينة قابلة للّمس.
    buffer.writeln(shareLink);

    return buffer.toString().trimRight();
  }

  /// رابط التطبيق مع مصدر التثبيت، ليُعرف كم لاعباً جاء من المشاركة.
  static String get shareLink => '${AppConfig.playStoreUrl}'
      '&referrer=${Uri.encodeComponent(AppConfig.shareReferrer)}';

  /// شبكة المربّعات بترتيب الأسئلة.
  String grid(QuizResult result) {
    return result.answers.map((a) {
      if (a.isCorrect) return correctSquare;
      // التخطّي وانتهاء الوقت يختلفان بصرياً عن الإجابة الخاطئة.
      if (a.selectedIndex < 0) return missedSquare;
      return wrongSquare;
    }).join();
  }
}
