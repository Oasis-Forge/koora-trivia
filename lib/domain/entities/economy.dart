/// أنواع المساعدات المتاحة داخل المستوى.
enum HintType { fiftyFifty, skip, extraTime }

/// حالة اقتصاد اللاعب: العملات والقلوب والمساعدات والمهام اليومية.
///
/// القلوب لا تُخزَّن كرصيد جامد بل كرصيد + لحظة آخر تجديد، ويُحسب الرصيد
/// الفعلي عند القراءة. هذا يجنّبنا مؤقّتاً يعمل في الخلفية.
class Economy {
  const Economy({
    this.hearts = AppEconomyDefaults.maxHearts,
    this.lastRegenAtIso,
    this.rewardedRefillsToday = 0,
    this.rewardedDayKey,
    this.hintsUsedToday = 0,
    this.hintsDayKey,
    this.coins = 0,
    this.bonusHints = 0,
    this.tasksDayKey,
    this.correctAnswersToday = 0,
    this.levelsCompletedToday = 0,
    this.dailyDoneToday = false,
    this.claimedTaskIds = const {},
    this.chestClaimed = false,
  });

  final int hearts;

  /// لحظة آخر احتساب للتجديد بصيغة ISO-8601.
  final String? lastRegenAtIso;

  final int rewardedRefillsToday;
  final String? rewardedDayKey;

  final int hintsUsedToday;
  final String? hintsDayKey;

  /// العملة الموحّدة للكسب والإنفاق.
  final int coins;

  /// مساعدات مشتراة بالعملات — لا تُصفَّر يومياً بخلاف المجانية.
  final int bonusHints;

  // ── تقدّم المهام اليومية ──
  final String? tasksDayKey;
  final int correctAnswersToday;
  final int levelsCompletedToday;
  final bool dailyDoneToday;

  /// معرّفات المهام التي استُلمت مكافآتها اليوم.
  final Set<String> claimedTaskIds;
  final bool chestClaimed;

  Economy copyWith({
    int? hearts,
    String? lastRegenAtIso,
    int? rewardedRefillsToday,
    String? rewardedDayKey,
    int? hintsUsedToday,
    String? hintsDayKey,
    int? coins,
    int? bonusHints,
    String? tasksDayKey,
    int? correctAnswersToday,
    int? levelsCompletedToday,
    bool? dailyDoneToday,
    Set<String>? claimedTaskIds,
    bool? chestClaimed,
  }) {
    return Economy(
      hearts: hearts ?? this.hearts,
      lastRegenAtIso: lastRegenAtIso ?? this.lastRegenAtIso,
      rewardedRefillsToday: rewardedRefillsToday ?? this.rewardedRefillsToday,
      rewardedDayKey: rewardedDayKey ?? this.rewardedDayKey,
      hintsUsedToday: hintsUsedToday ?? this.hintsUsedToday,
      hintsDayKey: hintsDayKey ?? this.hintsDayKey,
      coins: coins ?? this.coins,
      bonusHints: bonusHints ?? this.bonusHints,
      tasksDayKey: tasksDayKey ?? this.tasksDayKey,
      correctAnswersToday: correctAnswersToday ?? this.correctAnswersToday,
      levelsCompletedToday: levelsCompletedToday ?? this.levelsCompletedToday,
      dailyDoneToday: dailyDoneToday ?? this.dailyDoneToday,
      claimedTaskIds: claimedTaskIds ?? this.claimedTaskIds,
      chestClaimed: chestClaimed ?? this.chestClaimed,
    );
  }
}

/// قيم افتراضية مستقلة عن طبقة العرض حتى يبقى `domain` نظيفاً.
class AppEconomyDefaults {
  const AppEconomyDefaults._();
  static const int maxHearts = 5;
}
