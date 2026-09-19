/// إحصائيات المستخدم المحفوظة محلياً.
class UserStats {
  const UserStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestScore = 0,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.lastDailyDayKey,
    this.lastPlayedDayKey,
    this.streakShields = 0,
  });

  final int currentStreak;
  final int bestStreak;
  final int bestScore;
  final int totalScore;
  final int gamesPlayed;

  /// آخر يوم أُكمل فيه تحدي اليوم (`yyyy-MM-dd`).
  final String? lastDailyDayKey;

  /// آخر يوم لُعبت فيه أي جولة.
  final String? lastPlayedDayKey;

  /// حمايات سلسلة مشتراة بالعملات لم تُستعمل بعد — كل واحدة تغطي يوماً فائتاً.
  ///
  /// هنا لا في الاقتصاد: الحماية تُستعمل داخل حساب السلسلة نفسه، فتُحفظ معها في
  /// خطوة واحدة.
  final int streakShields;

  bool isDailyDoneOn(String dayKey) => lastDailyDayKey == dayKey;

  UserStats copyWith({
    int? currentStreak,
    int? bestStreak,
    int? bestScore,
    int? totalScore,
    int? gamesPlayed,
    String? lastDailyDayKey,
    String? lastPlayedDayKey,
    int? streakShields,
  }) {
    return UserStats(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestScore: bestScore ?? this.bestScore,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      lastDailyDayKey: lastDailyDayKey ?? this.lastDailyDayKey,
      lastPlayedDayKey: lastPlayedDayKey ?? this.lastPlayedDayKey,
      streakShields: streakShields ?? this.streakShields,
    );
  }
}
