import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';
import '../widgets/coin_badge.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/pitch_background.dart';
import '../widgets/rewarded_button.dart';

/// المتجر: إنفاق العملات على القلوب والمساعدات.
///
/// شراء العملات بالمال وإزالة الإعلانات معطّلان حتى تُضاف طبقة الدفع.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const String routeName = '/shop';

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.chalk,
                    ),
                    const Expanded(
                      child: Text(
                        AppStrings.shop,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const HeartsBar(compact: true),
                    const SizedBox(width: 8),
                    const CoinBadge(compact: true),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    _Row(
                      icon: Icons.favorite_rounded,
                      iconColor: AppColors.wrong,
                      label: AppStrings.refillHearts,
                      sublabel: '${economy.hearts}/${economy.maxHearts}',
                      price: AppConfig.priceHeartsRefill,
                      enabled: economy.canBuyHeartsRefill,
                      disabledReason: economy.isFull
                          ? AppStrings.heartsAlreadyFull
                          : AppStrings.notEnoughCoins,
                      onBuy: () =>
                          context.read<EconomyProvider>().buyHeartsRefill(),
                    ),
                    const SizedBox(height: 12),
                    _Row(
                      icon: Icons.lightbulb_rounded,
                      iconColor: AppColors.gold,
                      label:
                          '${AppStrings.hintsPack} (+${AppConfig.hintsPerPack})',
                      sublabel: '${economy.hintsLeft}',
                      price: AppConfig.priceHintsPack,
                      enabled: economy.canBuyHintsPack,
                      disabledReason: AppStrings.notEnoughCoins,
                      onBuy: () =>
                          context.read<EconomyProvider>().buyHintsPack(),
                    ),

                    const SizedBox(height: 26),
                    const Divider(),
                    const SizedBox(height: 14),

                    // الإعلان المكافأ يسدّ الفجوة بين دخل اليوم وسعر الشراء.
                    RewardedButton(
                      label: '${AppStrings.watchAdForCoins} '
                          '(+${AppConfig.coinsPerRewardedAd})',
                      onEarned: () =>
                          context.read<EconomyProvider>().grantRewardedCoins(),
                    ),
                    const SizedBox(height: 10),
                    const _ComingSoonRow(
                      icon: Icons.block_rounded,
                      label: AppStrings.removeAdsSoon,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.price,
    required this.enabled,
    required this.disabledReason,
    required this.onBuy,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final int price;
  final bool enabled;
  final String disabledReason;
  final Future<bool> Function() onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.chalkMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: FilledButton(
              onPressed: enabled ? () => _buy(context) : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.07),
                disabledForegroundColor: AppColors.chalkMuted,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$price',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.monetization_on_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await onBuy();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? AppStrings.purchased : disabledReason),
        ),
      );
  }
}

class _ComingSoonRow extends StatelessWidget {
  const _ComingSoonRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.chalkMuted, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.chalkMuted,
              ),
            ),
          ),
          Text(
            AppStrings.comingSoon,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.chalkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
