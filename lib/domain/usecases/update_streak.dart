import '../../core/utils/day_key.dart';
import '../entities/user_stats.dart';

/// منطق السلسلة اليومية.
///
/// القواعد:
/// - تزيد السلسلة بواحد إذا كان آخر تحدٍ مكتمل بالأمس.
/// - تبقى كما هي إذا كان التحدي قد أُنجز اليوم بالفعل (لا تكرار).
/// - تُعاد إلى 1 إذا مرّ يوم أو أكثر دون إنجاز.
class UpdateStreak {
  const UpdateStreak();

  UserStats call(UserStats stats, {required String todayKey}) {
    final last = stats.lastDailyDayKey;

    final int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final gap = DayKey.daysBetween(last, todayKey);
      newStreak = switch (gap) {
        0 => stats.currentStreak == 0 ? 1 : stats.currentStreak,
        1 => stats.currentStreak + 1,
        _ => 1,
      };
    }

    return stats.copyWith(
      currentStreak: newStreak,
      bestStreak: newStreak > stats.bestStreak ? newStreak : stats.bestStreak,
      lastDailyDayKey: todayKey,
    );
  }

  /// السلسلة المعروضة بعد التحقق من انقطاعها (دون حفظ).
  ///
  /// إذا مرّ أكثر من يوم على آخر تحدٍ فالسلسلة منقطعة فعلياً.
  static int visibleStreak(UserStats stats, String todayKey) {
    final last = stats.lastDailyDayKey;
    if (last == null) return 0;
    return DayKey.daysBetween(last, todayKey) <= 1 ? stats.currentStreak : 0;
  }
}
