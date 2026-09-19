import '../../core/constants/app_config.dart';
import '../../domain/entities/user_stats.dart';

class UserStatsModel extends UserStats {
  const UserStatsModel({
    super.currentStreak,
    super.bestStreak,
    super.bestScore,
    super.totalScore,
    super.gamesPlayed,
    super.lastDailyDayKey,
    super.lastPlayedDayKey,
    super.streakShields,
  });

  factory UserStatsModel.fromEntity(UserStats stats) {
    return UserStatsModel(
      currentStreak: stats.currentStreak,
      bestStreak: stats.bestStreak,
      bestScore: stats.bestScore,
      totalScore: stats.totalScore,
      gamesPlayed: stats.gamesPlayed,
      lastDailyDayKey: stats.lastDailyDayKey,
      lastPlayedDayKey: stats.lastPlayedDayKey,
      streakShields: stats.streakShields,
    );
  }

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      lastDailyDayKey: json['lastDailyDayKey'] as String?,
      lastPlayedDayKey: json['lastPlayedDayKey'] as String?,
      // السقف يُفرض عند القراءة أيضاً: نسخة احتياطية معدّلة لا تحمل عشر حمايات.
      streakShields: (json['streakShields'] as int? ?? 0)
          .clamp(0, AppConfig.maxStreakShields),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'bestScore': bestScore,
        'totalScore': totalScore,
        'gamesPlayed': gamesPlayed,
        'lastDailyDayKey': lastDailyDayKey,
        'lastPlayedDayKey': lastPlayedDayKey,
        'streakShields': streakShields,
      };
}
