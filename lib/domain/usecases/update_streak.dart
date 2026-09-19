import '../../core/constants/app_config.dart';
import '../../core/utils/day_key.dart';
import '../entities/user_stats.dart';

/// ما حدث للسلسلة عند إكمال تحدي اليوم، لتعرضه شاشة النتيجة.
class StreakUpdate {
  const StreakUpdate({this.shieldUsed = false, this.rewardCoins = 0});

  static const StreakUpdate none = StreakUpdate();

  /// غطّت حماية مشتراة يوماً فائتاً، فاستمرت السلسلة.
  final bool shieldUsed;

  /// عملات أيام السلسلة التي بُلغت أول مرة (7 و30 و100)، أو صفر.
  final int rewardCoins;
}

/// منطق السلسلة اليومية.
///
/// القواعد:
/// - تزيد السلسلة بواحد إذا كان آخر تحدٍ مكتمل بالأمس.
/// - تبقى كما هي إذا كان التحدي قد أُنجز اليوم بالفعل (لا تكرار).
/// - فاتها يوم واحد ومع اللاعب حماية: تُستعمل الحماية وتزيد السلسلة بواحد، فاليوم
///   الفائت لا يُحتسب لها ولا عليها.
/// - تُعاد إلى 1 إذا مرّ يوم أو أكثر دون إنجاز ودون حماية.
class UpdateStreak {
  const UpdateStreak();

  UserStats call(UserStats stats, {required String todayKey}) {
    final last = stats.lastDailyDayKey;

    var shields = stats.streakShields;
    final int newStreak;
    if (last == null) {
      newStreak = 1;
    } else {
      final gap = DayKey.daysBetween(last, todayKey);
      if (_shieldCovers(stats, gap)) {
        shields--;
        newStreak = stats.currentStreak + 1;
      } else {
        newStreak = switch (gap) {
          0 => stats.currentStreak == 0 ? 1 : stats.currentStreak,
          1 => stats.currentStreak + 1,
          _ => 1,
        };
      }
    }

    return stats.copyWith(
      currentStreak: newStreak,
      bestStreak: newStreak > stats.bestStreak ? newStreak : stats.bestStreak,
      lastDailyDayKey: todayKey,
      streakShields: shields,
    );
  }

  /// الحماية تغطي يوماً فائتاً واحداً فقط (فجوة يومين)، ولسلسلة قائمة: من فاته
  /// يومان خسر سلسلته وبقيت حمايته له، فلم تنفعه في شيء.
  static bool _shieldCovers(UserStats stats, int gap) =>
      gap == 2 && stats.streakShields > 0 && stats.currentStreak > 0;

  /// السلسلة المعروضة بعد التحقق من انقطاعها (دون حفظ).
  ///
  /// إذا مرّ أكثر من يوم على آخر تحدٍ فالسلسلة منقطعة فعلياً — إلا يوماً واحداً
  /// تغطيه حماية، فتبقى ظاهرة حتى يُكمل تحدي اليوم فتُستعمل.
  static int visibleStreak(UserStats stats, String todayKey) {
    final last = stats.lastDailyDayKey;
    if (last == null) return 0;
    final gap = DayKey.daysBetween(last, todayKey);
    return gap <= 1 || _shieldCovers(stats, gap) ? stats.currentStreak : 0;
  }

  /// ما تغيّر بين السلسلة قبل إكمال التحدي وبعده.
  ///
  /// المكافأة على «أفضل سلسلة» لا على الحالية، فكل عدد أيام يُكافأ مرة واحدة.
  static StreakUpdate changes(UserStats before, UserStats after) {
    var coins = 0;
    for (final MapEntry(key: days, value: reward)
        in AppConfig.streakMilestoneCoins.entries) {
      if (before.bestStreak < days && after.bestStreak >= days) coins += reward;
    }
    return StreakUpdate(
      shieldUsed: after.streakShields < before.streakShields,
      rewardCoins: coins,
    );
  }
}
