import '../../core/constants/app_strings.dart';
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
      buffer.writeln('🔥 $streak ${_dayWord(streak)} متتالية');
    }

    return buffer.toString().trimRight();
  }

  /// شبكة المربّعات بترتيب الأسئلة.
  String grid(QuizResult result) {
    return result.answers.map((a) {
      if (a.isCorrect) return correctSquare;
      // التخطّي وانتهاء الوقت يختلفان بصرياً عن الإجابة الخاطئة.
      if (a.selectedIndex < 0) return missedSquare;
      return wrongSquare;
    }).join();
  }

  /// تمييز المثنى في العربية: "يومان" لا "2 يوم".
  String _dayWord(int streak) => streak == 2 ? 'يومان' : 'أيام';
}
