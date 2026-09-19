import '../../core/constants/app_config.dart';
import 'economy_provider.dart';
import 'stats_provider.dart';

/// شراء حماية السلسلة: العملات من الاقتصاد، والحماية تُحفظ مع السلسلة.
///
/// الخصم أولاً ثم الإضافة: لو فشلت الإضافة بعد الخصم فهي خسارة نادرة، أما العكس
/// فحماية مجانية لكل من يغلق التطبيق في اللحظة المناسبة.
class BuyStreakShield {
  const BuyStreakShield({
    required StatsProvider stats,
    required EconomyProvider economy,
  })  : _stats = stats,
        _economy = economy;

  final StatsProvider _stats;
  final EconomyProvider _economy;

  Future<bool> call() async {
    if (!_stats.canHoldShield) return false;
    if (!await _economy.spendCoins(AppConfig.priceStreakShield)) return false;
    return _stats.addStreakShield();
  }
}
