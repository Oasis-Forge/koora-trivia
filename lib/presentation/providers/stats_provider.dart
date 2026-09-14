import 'package:flutter/foundation.dart';

import '../../core/utils/day_key.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/repositories/stats_repository.dart';
import '../../domain/usecases/update_streak.dart';

class StatsProvider extends ChangeNotifier {
  StatsProvider({
    required StatsRepository repository,
    UpdateStreak updateStreak = const UpdateStreak(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _updateStreak = updateStreak,
        _clock = clock ?? DateTime.now;

  final StatsRepository _repository;
  final UpdateStreak _updateStreak;

  /// ساعة ثابتة في الاختبارات حتى لا يتغير «اليوم» بين تجهيز الاختبار وتنفيذه.
  final DateTime Function() _clock;

  UserStats _stats = const UserStats();
  bool _loading = true;

  UserStats get stats => _stats;
  bool get isLoading => _loading;

  String get todayKey => DayKey.today(_clock());

  /// السلسلة الحالية بعد احتساب الانقطاع.
  int get streak => UpdateStreak.visibleStreak(_stats, todayKey);
  int get bestStreak => _stats.bestStreak;
  bool get isDailyDone => _stats.isDailyDoneOn(todayKey);

  /// الوقت المتبقي حتى تحدي الغد.
  Duration get untilNextDaily => DayKey.untilTomorrow(_clock());

  Future<void> init() async {
    _stats = await _repository.load();
    _loading = false;
    notifyListeners();
  }

  /// تسجيل نتيجة جولة منتهية وتحديث السلسلة عند اكتمال تحدي اليوم.
  Future<void> recordResult(QuizResult result) async {
    final today = todayKey;

    var next = _stats.copyWith(
      gamesPlayed: _stats.gamesPlayed + 1,
      totalScore: _stats.totalScore + result.score,
      bestScore:
          result.score > _stats.bestScore ? result.score : _stats.bestScore,
      lastPlayedDayKey: today,
    );

    if (result.isDaily) {
      // يوم بدء التحدي لا يوم انتهائه: من بدأ قبل منتصف الليل وأنهى بعده كانت
      // سلسلته تُعاد إلى 1 (انظر `QuizProvider.startDaily`).
      final dayKey = result.dailyDayKey ?? today;
      if (!next.isDailyDoneOn(dayKey)) {
        next = _updateStreak(next, todayKey: dayKey);
      }
    }

    _stats = next;
    notifyListeners();
    await _repository.save(next);
  }

  Future<void> resetAll() async {
    _stats = const UserStats();
    notifyListeners();
    await _repository.save(_stats);
  }
}
