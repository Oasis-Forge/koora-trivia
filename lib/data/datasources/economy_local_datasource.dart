import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_config.dart';
import '../../domain/entities/economy.dart';

abstract class EconomyLocalDataSource {
  Future<Economy> read();
  Future<void> write(Economy economy);
}

class PrefsEconomyDataSource implements EconomyLocalDataSource {
  static const String _key = 'economy_v1';

  @override
  Future<Economy> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const Economy(hearts: AppConfig.maxHearts);
    }

    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return Economy(
        hearts: (map['hearts'] as int? ?? AppConfig.maxHearts)
            .clamp(0, AppConfig.maxHearts),
        lastRegenAtIso: map['lastRegenAtIso'] as String?,
        rewardedRefillsToday: map['rewardedRefillsToday'] as int? ?? 0,
        rewardedDayKey: map['rewardedDayKey'] as String?,
        hintsUsedToday: map['hintsUsedToday'] as int? ?? 0,
        hintsDayKey: map['hintsDayKey'] as String?,
        coins: map['coins'] as int? ?? 0,
        bonusHints: map['bonusHints'] as int? ?? 0,
        tasksDayKey: map['tasksDayKey'] as String?,
        correctAnswersToday: map['correctAnswersToday'] as int? ?? 0,
        levelsCompletedToday: map['levelsCompletedToday'] as int? ?? 0,
        dailyDoneToday: map['dailyDoneToday'] as bool? ?? false,
        claimedTaskIds:
            ((map['claimedTaskIds'] as List<dynamic>?) ?? const [])
                .map((e) => e as String)
                .toSet(),
        chestClaimed: map['chestClaimed'] as bool? ?? false,
      );
    } on FormatException {
      await prefs.remove(_key);
      return const Economy(hearts: AppConfig.maxHearts);
    }
  }

  @override
  Future<void> write(Economy economy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode({
        'hearts': economy.hearts,
        'lastRegenAtIso': economy.lastRegenAtIso,
        'rewardedRefillsToday': economy.rewardedRefillsToday,
        'rewardedDayKey': economy.rewardedDayKey,
        'hintsUsedToday': economy.hintsUsedToday,
        'hintsDayKey': economy.hintsDayKey,
        'coins': economy.coins,
        'bonusHints': economy.bonusHints,
        'tasksDayKey': economy.tasksDayKey,
        'correctAnswersToday': economy.correctAnswersToday,
        'levelsCompletedToday': economy.levelsCompletedToday,
        'dailyDoneToday': economy.dailyDoneToday,
        'claimedTaskIds': economy.claimedTaskIds.toList(),
        'chestClaimed': economy.chestClaimed,
      }),
    );
  }
}
