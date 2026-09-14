import 'package:flutter/foundation.dart';

import '../../core/constants/app_config.dart';
import '../../core/utils/day_key.dart';
import '../../domain/entities/daily_task.dart';
import '../../domain/entities/economy.dart';
import '../../domain/repositories/economy_repository.dart';
import '../../domain/usecases/regenerate_hearts.dart';

class EconomyProvider extends ChangeNotifier {
  EconomyProvider({
    required EconomyRepository repository,
    RegenerateHearts regenerate = const RegenerateHearts(),
    DateTime Function()? clock,
  })  : _repository = repository,
        _regenerate = regenerate,
        _clock = clock ?? DateTime.now;

  final EconomyRepository _repository;
  final RegenerateHearts _regenerate;
  final DateTime Function() _clock;

  Economy _economy = const Economy();
  Duration? _untilNextHeart;
  bool _loading = true;

  bool get isLoading => _loading;
  int get hearts => _economy.hearts;
  int get maxHearts => AppConfig.maxHearts;
  bool get hasHearts => _economy.hearts > 0;
  bool get isFull => _economy.hearts >= AppConfig.maxHearts;
  Duration? get untilNextHeart => _untilNextHeart;

  int get coins => _economy.coins;

  int get freeHintsLeft =>
      (AppConfig.freeHintsPerDay - _economy.hintsUsedToday).clamp(0, 99);

  /// المجاني اليومي + المشترى بالعملات.
  int get hintsLeft => freeHintsLeft + _economy.bonusHints;
  bool get hasHints => hintsLeft > 0;

  // ── المهام اليومية ──

  List<DailyTask> get tasks => [
        _task(
          TaskKind.correctAnswers,
          _economy.correctAnswersToday,
          AppConfig.taskAnswersTarget,
          AppConfig.coinsTaskAnswers,
        ),
        _task(
          TaskKind.completeDaily,
          _economy.dailyDoneToday ? 1 : 0,
          1,
          AppConfig.coinsTaskDaily,
        ),
        _task(
          TaskKind.completeLevel,
          _economy.levelsCompletedToday,
          1,
          AppConfig.coinsTaskLevel,
        ),
      ];

  DailyTask _task(TaskKind kind, int progress, int target, int reward) =>
      DailyTask(
        kind: kind,
        progress: progress,
        target: target,
        reward: reward,
        claimed: _economy.claimedTaskIds.contains(kind.id),
      );

  /// الصندوق يُفتح بعد استلام كل المهام.
  bool get chestReady =>
      !_economy.chestClaimed && tasks.every((t) => t.claimed);
  bool get chestClaimed => _economy.chestClaimed;

  /// عدد المهام الجاهزة للاستلام — يُستخدم لنقطة التنبيه في الواجهة.
  int get claimableCount =>
      tasks.where((t) => t.isClaimable).length + (chestReady ? 1 : 0);

  int get rewardedRefillsLeft =>
      (AppConfig.maxRewardedRefillsPerDay - _economy.rewardedRefillsToday)
          .clamp(0, 99);
  bool get canWatchRewarded => rewardedRefillsLeft > 0 && !isFull;

  Future<void> init() async {
    _economy = await _repository.load();
    _refresh(persist: false);
    _loading = false;
    notifyListeners();
  }

  /// إعادة احتساب الرصيد والعدّاد والمهام اليومية.
  ///
  /// تُستدعى عند العودة إلى التطبيق، وكل نصف دقيقة من `HeartsTicker` ما دامت
  /// القلوب ناقصة، وقبل بدء أي مستوى.
  void refresh() => _refresh(persist: true);

  void _refresh({required bool persist}) {
    final before = _economy;
    final minutesBefore = _untilNextHeart?.inMinutes;
    final snapshot = _regenerate(_economy, now: _clock());
    _economy = snapshot.economy;
    _untilNextHeart = snapshot.untilNextHeart;

    if (!persist) return;
    final changed = !identical(before, _economy);
    if (changed) _repository.save(_economy);

    // العدّاد وحده يتغيّر كل دقيقة دون أي تغيّر يُحفظ، وكان لا يُخطر الواجهة
    // فيبقى الوقت المعروض مجمّداً.
    if (changed || _untilNextHeart?.inMinutes != minutesBefore) {
      notifyListeners();
    }
  }

  /// خصم قلب المحاولة عند بدء مستوى (`NoHeartsDialog.startLevel`). يعيد `false`
  /// إن لم يكن هناك رصيد.
  Future<bool> consumeHeart() async {
    _refresh(persist: false);
    if (_economy.hearts <= 0) return false;

    // بدء عدّاد التجديد من لحظة أول نقص عن الحد الأقصى.
    final wasFull = _economy.hearts >= AppConfig.maxHearts;
    _economy = _economy.copyWith(
      hearts: _economy.hearts - 1,
      lastRegenAtIso:
          wasFull ? _clock().toIso8601String() : _economy.lastRegenAtIso,
    );
    // يظهر عدّاد القلب التالي فور خسارة القلب، لا بعد إعادة الحساب التالية.
    _refresh(persist: false);

    notifyListeners();
    await _repository.save(_economy);
    return true;
  }

  /// إعادة قلب المحاولة عند اجتياز المستوى: المحاولة الناجحة لا تكلّف شيئاً.
  Future<void> refundLevelHeart() => _grantHearts(1);

  /// منح قلب مقابل إكمال تحدي اليوم.
  Future<void> grantDailyChallengeHeart() =>
      _grantHearts(AppConfig.heartsForDailyChallenge);

  /// منح قلب مقابل إعلان مكافأ. يعيد `false` إذا استُنفد الحد اليومي.
  Future<bool> grantRewardedHearts() async {
    _refresh(persist: false);
    if (!canWatchRewarded) return false;

    _economy = _economy.copyWith(
      rewardedRefillsToday: _economy.rewardedRefillsToday + 1,
      rewardedDayKey: DayKey.today(_clock()),
    );
    await _grantHearts(AppConfig.heartsPerRewardedAdWatch);
    return true;
  }

  /// منح عملات مقابل إعلان مكافأ — بلا حدّ يومي، فالإعلان نفسه هو الكلفة.
  Future<void> grantRewardedCoins() =>
      _addCoins(AppConfig.coinsPerRewardedAd);

  Future<void> _grantHearts(int amount) async {
    if (amount <= 0) return;
    _refresh(persist: false);

    final hearts = (_economy.hearts + amount).clamp(0, AppConfig.maxHearts);
    _economy = _economy.copyWith(hearts: hearts);
    // العدّاد يُحسب من لحظة آخر تجديد: القلب الممنوح لا يعيد انتظار القلب
    // التالي إلى ثلاثين دقيقة كاملة كما كان.
    _refresh(persist: false);

    notifyListeners();
    await _repository.save(_economy);
  }

  /// استهلاك مساعدة — المجانية أولاً ثم المشتراة.
  Future<bool> consumeHint() async {
    _refresh(persist: false);
    if (hintsLeft <= 0) return false;

    if (freeHintsLeft > 0) {
      _economy = _economy.copyWith(
        hintsUsedToday: _economy.hintsUsedToday + 1,
        hintsDayKey: DayKey.today(_clock()),
      );
    } else {
      _economy = _economy.copyWith(bonusHints: _economy.bonusHints - 1);
    }

    notifyListeners();
    await _repository.save(_economy);
    return true;
  }

  // ── العملات والمهام ──

  Future<void> _addCoins(int amount) async {
    if (amount <= 0) return;
    _economy = _economy.copyWith(coins: _economy.coins + amount);
    notifyListeners();
    await _repository.save(_economy);
  }

  /// تسجيل إجابة صحيحة لمهمة الإجابات.
  Future<void> recordCorrectAnswer() async {
    _refresh(persist: false);
    _economy = _economy.copyWith(
      correctAnswersToday: _economy.correctAnswersToday + 1,
      tasksDayKey: DayKey.today(_clock()),
    );
    notifyListeners();
    await _repository.save(_economy);
  }

  /// تسجيل اجتياز مستوى لمهمة المستويات.
  Future<void> recordLevelCompleted() async {
    _refresh(persist: false);
    _economy = _economy.copyWith(
      levelsCompletedToday: _economy.levelsCompletedToday + 1,
      tasksDayKey: DayKey.today(_clock()),
    );
    notifyListeners();
    await _repository.save(_economy);
  }

  /// تسجيل إكمال تحدي اليوم لمهمة التحدي.
  Future<void> recordDailyCompleted() async {
    _refresh(persist: false);
    _economy = _economy.copyWith(
      dailyDoneToday: true,
      tasksDayKey: DayKey.today(_clock()),
    );
    notifyListeners();
    await _repository.save(_economy);
  }

  /// استلام مكافأة مهمة مكتملة. يعيد عدد العملات الممنوحة أو صفراً.
  Future<int> claimTask(TaskKind kind) async {
    _refresh(persist: false);

    final task = tasks.firstWhere((t) => t.kind == kind);
    if (!task.isClaimable) return 0;

    _economy = _economy.copyWith(
      claimedTaskIds: {..._economy.claimedTaskIds, kind.id},
    );
    await _addCoins(task.reward);
    return task.reward;
  }

  /// فتح الصندوق بعد استلام كل المهام.
  Future<int> claimChest() async {
    _refresh(persist: false);
    if (!chestReady) return 0;

    _economy = _economy.copyWith(chestClaimed: true);
    await _addCoins(AppConfig.coinsChestBonus);
    return AppConfig.coinsChestBonus;
  }

  // ── المتجر ──

  bool get canBuyHeartsRefill =>
      _economy.coins >= AppConfig.priceHeartsRefill && !isFull;
  bool get canBuyHintsPack => _economy.coins >= AppConfig.priceHintsPack;

  /// ملء القلوب حتى الحد الأقصى مقابل عملات.
  ///
  /// نبيع "ملء" لا عدداً ثابتاً لأن سقف القلوب خمسة، فبيع عشرين قلباً بلا معنى.
  Future<bool> buyHeartsRefill() async {
    _refresh(persist: false);
    if (!canBuyHeartsRefill) return false;

    _economy = _economy.copyWith(
      coins: _economy.coins - AppConfig.priceHeartsRefill,
      hearts: AppConfig.maxHearts,
    );
    _untilNextHeart = null;
    notifyListeners();
    await _repository.save(_economy);
    return true;
  }

  Future<bool> buyHintsPack() async {
    _refresh(persist: false);
    if (!canBuyHintsPack) return false;

    _economy = _economy.copyWith(
      coins: _economy.coins - AppConfig.priceHintsPack,
      bonusHints: _economy.bonusHints + AppConfig.hintsPerPack,
    );
    notifyListeners();
    await _repository.save(_economy);
    return true;
  }

  @visibleForTesting
  Economy get raw => _economy;
}
