import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
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

  int get streakShields => _stats.streakShields;
  bool get canHoldShield => _stats.streakShields < AppConfig.maxStreakShields;

  /// الوقت المتبقي حتى تحدي الغد.
  Duration get untilNextDaily => DayKey.untilTomorrow(_clock());

  Future<void> init() async {
    _stats = await _repository.load();
    _loading = false;
    notifyListeners();
  }

  /// تسجيل نتيجة جولة منتهية وتحديث السلسلة عند اكتمال تحدي اليوم.
  ///
  /// يعيد ما حدث للسلسلة: حماية استُعملت، وعملات أيامها إن بلغت 7 أو 30 أو 100
  /// أول مرة — يمنحها `RecordRound`، فالعملات في الاقتصاد لا هنا.
  Future<StreakUpdate> recordResult(QuizResult result) async {
    final today = todayKey;

    var next = _stats.copyWith(
      gamesPlayed: _stats.gamesPlayed + 1,
      totalScore: _stats.totalScore + result.score,
      bestScore:
          result.score > _stats.bestScore ? result.score : _stats.bestScore,
      lastPlayedDayKey: today,
    );

    var update = StreakUpdate.none;
    if (result.isDaily) {
      // يوم بدء التحدي لا يوم انتهائه: من بدأ قبل منتصف الليل وأنهى بعده كانت
      // سلسلته تُعاد إلى 1 (انظر `QuizProvider.startDaily`).
      final dayKey = result.dailyDayKey ?? today;
      if (!next.isDailyDoneOn(dayKey)) {
        final before = next;
        next = _updateStreak(next, todayKey: dayKey);
        update = UpdateStreak.changes(before, next);
      }
    }

    _stats = next;
    notifyListeners();
    await _repository.save(next);
    return update;
  }

  /// إضافة حماية سلسلة بعد خصم ثمنها (`BuyStreakShield`). يعيد `false` إن كان
  /// اللاعب يحمل الحد الأقصى.
  Future<bool> addStreakShield() async {
    if (!canHoldShield) return false;
    _stats = _stats.copyWith(streakShields: _stats.streakShields + 1);
    notifyListeners();
    await _repository.save(_stats);
    return true;
  }

  Future<void> resetAll() async {
    _stats = const UserStats();
    notifyListeners();
    await _repository.save(_stats);
  }
}
