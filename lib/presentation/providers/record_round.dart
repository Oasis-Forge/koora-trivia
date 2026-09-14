import 'package:flutter/foundation.dart';

import '../../core/utils/day_key.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/usecases/evaluate_level.dart';
import 'economy_provider.dart';
import 'progress_provider.dart';
import 'stats_provider.dart';

/// ما تغيّر بحفظ الجولة، لتعرضه شاشة النتيجة.
class RoundRecord {
  const RoundRecord({
    this.earnedHeart = false,
    this.lostHeart = false,
    this.level,
  });

  /// أُضيف قلب تحدي اليوم فعلاً.
  final bool earnedHeart;

  /// مستوى لم يُجتز: ذهب قلب المحاولة الذي خُصم عند بدئها.
  final bool lostHeart;

  /// نتيجة المستوى، أو `null` خارج المستويات أو إن تعثّر حفظ النجوم.
  final LevelOutcome? level;
}

/// يحفظ نهاية الجولة كلها في مكان واحد: الإحصائيات والسلسلة، قلب تحدي اليوم
/// ومهمته، قلب محاولة المستوى ونجومه ومهمته.
///
/// كان الحفظ داخل استدعاء بعد الإطار في شاشة النتيجة: أخطاؤه لا تظهر على الشاشة
/// (هكذا اختبأ عطل حفظ النجوم)، ومغادرة الشاشة بسرعة كانت توقف ما بقي منه. هنا
/// لا يتوقف الحفظ بمغادرة الشاشة، وكل خطوة مستقلة: فشل واحدة يُسجَّل في سجل
/// الأخطاء ولا يمنع البقية.
class RecordRound {
  const RecordRound({
    required StatsProvider stats,
    required EconomyProvider economy,
    required ProgressProvider progress,
    EvaluateLevel evaluate = const EvaluateLevel(),
  })  : _stats = stats,
        _economy = economy,
        _progress = progress,
        _evaluate = evaluate;

  final StatsProvider _stats;
  final EconomyProvider _economy;
  final ProgressProvider _progress;
  final EvaluateLevel _evaluate;

  Future<RoundRecord> call(QuizResult result) async {
    await _step('stats', () => _stats.recordResult(result));

    var earnedHeart = false;
    if (result.isDaily) {
      // قلب واحد لكل يوم تحدٍّ، ويوم التحدي يوم بدئه كما في السلسلة.
      await _step('daily heart', () async {
        earnedHeart = await _economy.grantDailyChallengeHeart(
          dayKey: result.dailyDayKey ?? DayKey.today(),
        );
      });
      await _step('daily task', _economy.recordDailyCompleted);
    }

    if (!result.isLevel) return RoundRecord(earnedHeart: earnedHeart);

    // قلب المحاولة خُصم عند بدئها ويعود عند الاجتياز — قبل حفظ النجوم، فلا يضيع
    // على من اجتاز إن تعثّر حفظها.
    final passed =
        _evaluate.passed(correct: result.correctCount, total: result.total);
    if (passed) await _step('level heart refund', _economy.refundLevelHeart);

    LevelOutcome? outcome;
    await _step('level stars', () async {
      outcome = await _progress.recordLevelResult(result);
    });

    // المهمة تُحتسب على اجتياز المستوى لا على مجرد لعبه.
    if (outcome?.passed ?? false) {
      await _step('level task', _economy.recordLevelCompleted);
    }

    return RoundRecord(lostHeart: !passed, level: outcome);
  }

  static Future<void> _step(String name, Future<void> Function() save) async {
    try {
      await save();
    } catch (e, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'record_round',
          context: ErrorDescription('أثناء حفظ نهاية الجولة ($name)'),
        ),
      );
    }
  }
}
