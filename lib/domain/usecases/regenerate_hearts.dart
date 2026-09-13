import '../../core/constants/app_config.dart';
import '../../core/utils/day_key.dart';
import '../entities/economy.dart';

/// نتيجة احتساب التجديد.
class HeartsSnapshot {
  const HeartsSnapshot({required this.economy, required this.untilNextHeart});

  final Economy economy;

  /// الوقت المتبقي حتى القلب التالي، أو `null` عند امتلاء الرصيد.
  final Duration? untilNextHeart;
}

/// يحسب رصيد القلوب الفعلي من الرصيد المخزّن ولحظة آخر تجديد.
///
/// يُستدعى عند كل قراءة بدل تشغيل مؤقّت في الخلفية.
class RegenerateHearts {
  const RegenerateHearts();

  HeartsSnapshot call(Economy stored, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final regen = Duration(minutes: AppConfig.heartRegenMinutes);

    // تصفير الحدود اليومية عند تغيّر اليوم.
    final today = DayKey.from(moment);
    var economy = stored;
    if (economy.rewardedDayKey != today) {
      economy = economy.copyWith(rewardedRefillsToday: 0, rewardedDayKey: today);
    }
    if (economy.hintsDayKey != today) {
      economy = economy.copyWith(hintsUsedToday: 0, hintsDayKey: today);
    }
    if (economy.tasksDayKey != today) {
      // العملات والمساعدات المشتراة لا تُصفَّر — فقط تقدّم مهام اليوم.
      economy = economy.copyWith(
        tasksDayKey: today,
        correctAnswersToday: 0,
        levelsCompletedToday: 0,
        dailyDoneToday: false,
        claimedTaskIds: const {},
        chestClaimed: false,
      );
    }

    if (economy.hearts >= AppConfig.maxHearts) {
      return HeartsSnapshot(
        economy: economy.copyWith(lastRegenAtIso: moment.toIso8601String()),
        untilNextHeart: null,
      );
    }

    final lastIso = economy.lastRegenAtIso;
    if (lastIso == null) {
      return HeartsSnapshot(
        economy: economy.copyWith(lastRegenAtIso: moment.toIso8601String()),
        untilNextHeart: regen,
      );
    }

    final last = DateTime.tryParse(lastIso);
    if (last == null) {
      return HeartsSnapshot(
        economy: economy.copyWith(lastRegenAtIso: moment.toIso8601String()),
        untilNextHeart: regen,
      );
    }

    var elapsed = moment.difference(last);

    // ساعة الجهاز رجعت للخلف — نعيد ضبط المرجع بدل منح رصيد سالب.
    if (elapsed.isNegative) {
      return HeartsSnapshot(
        economy: economy.copyWith(lastRegenAtIso: moment.toIso8601String()),
        untilNextHeart: regen,
      );
    }

    final earned = elapsed.inMinutes ~/ AppConfig.heartRegenMinutes;
    if (earned <= 0) {
      return HeartsSnapshot(
        economy: economy,
        untilNextHeart: regen - elapsed,
      );
    }

    final hearts = (economy.hearts + earned).clamp(0, AppConfig.maxHearts);
    final full = hearts >= AppConfig.maxHearts;

    // نحتفظ بالبقية حتى لا تضيع دقائق الانتظار عند كل قراءة.
    final consumed = Duration(minutes: earned * AppConfig.heartRegenMinutes);
    final newLast = full ? moment : last.add(consumed);
    final remainder = full ? Duration.zero : moment.difference(newLast);

    return HeartsSnapshot(
      economy: economy.copyWith(
        hearts: hearts,
        lastRegenAtIso: newLast.toIso8601String(),
      ),
      untilNextHeart: full ? null : regen - remainder,
    );
  }
}
