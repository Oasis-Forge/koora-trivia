import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/store_product.dart';
import '../providers/economy_provider.dart';
import '../providers/purchases_provider.dart';
import '../widgets/banner_slot.dart';
import '../widgets/coin_badge.dart';
import '../widgets/hearts_bar.dart';
import '../widgets/koora_app_bar.dart';
import '../widgets/pitch_background.dart';
import '../widgets/rewarded_button.dart';
import '../widgets/surface.dart';

/// المتجر: إنفاق العملات على القلوب والمساعدات، وشراء بالمال الحقيقي.
///
/// صفّ الشراء بالمال لا يظهر إلا حين يردّ المتجر منتجاته فعلاً؛ قبل ذلك (ملف
/// دفع تحت التحقق، أو منتجات لم تُنشأ بعد) يبقى صفّ «قريباً» كما كان.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const String routeName = '/shop';

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final purchases = context.watch<PurchasesProvider>();

    return Scaffold(
      // الشريط الإعلاني أسفل المحتوى دائماً، لا داخل التمرير.
      bottomNavigationBar: const BannerSlot(),
      body: PitchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              KooraAppBar(title: AppStrings.shop),
              const SizedBox(height: 16),
              const Row(
                children: [
                  HeartsBar(),
                  SizedBox(width: 8),
                  CoinBadge(),
                ],
              ),
              const SizedBox(height: 16),
              _Item(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.wrong,
                label: AppStrings.refillHearts,
                sublabel: '${economy.hearts}/${economy.maxHearts}',
                price: AppConfig.priceHeartsRefill,
                enabled: economy.canBuyHeartsRefill,
                disabledReason: economy.isFull
                    ? AppStrings.heartsAlreadyFull
                    : AppStrings.notEnoughCoins,
                onBuy: () => context.read<EconomyProvider>().buyHeartsRefill(),
              ),
              const SizedBox(height: 12),
              _Item(
                icon: Icons.lightbulb_rounded,
                iconColor: AppColors.gold,
                label: '${AppStrings.hintsPack} (+${AppConfig.hintsPerPack})',
                sublabel: '${economy.hintsLeft}',
                price: AppConfig.priceHintsPack,
                enabled: economy.canBuyHintsPack,
                disabledReason: AppStrings.notEnoughCoins,
                onBuy: () => context.read<EconomyProvider>().buyHintsPack(),
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 16),
              // الإعلان المكافأ يسدّ الفجوة بين دخل اليوم وسعر الشراء.
              RewardedButton(
                label: '${AppStrings.watchAdForCoins} '
                    '(+${AppConfig.coinsPerRewardedAd})',
                onEarned: () =>
                    context.read<EconomyProvider>().grantRewardedCoins(),
              ),
              const SizedBox(height: 16),
              if (!purchases.isAvailable)
                _ComingSoonRow(
                  icon: Icons.block_rounded,
                  label: AppStrings.removeAds,
                )
              else ...[
                for (final product in purchases.products) ...[
                  _PaidItem(
                    product: product,
                    owned: product.kind == StoreProductKind.removeAds &&
                        purchases.adsRemoved,
                    busy: purchases.busy == product.kind,
                  ),
                  const SizedBox(height: 12),
                ],
                _RestoreRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// صفّ منتج يُشترى بالمال. السعر نصّ من المتجر بعملة اللاعب، لا رقم نحسبه.
class _PaidItem extends StatelessWidget {
  const _PaidItem({
    required this.product,
    required this.owned,
    required this.busy,
  });

  final StoreProduct product;
  final bool owned;
  final bool busy;

  static String _label(StoreProduct product) => switch (product.kind) {
        StoreProductKind.removeAds => AppStrings.removeAds,
        StoreProductKind.coinsSmall => AppStrings.coinsPack(
            ArabicCount.format(AppConfig.coinsPerSmallPack, ArabicNoun.coin),
          ),
        StoreProductKind.coinsLarge => AppStrings.coinsPack(
            ArabicCount.format(AppConfig.coinsPerLargePack, ArabicNoun.coin),
          ),
      };

  static String _hint(StoreProduct product) =>
      product.kind == StoreProductKind.removeAds
          ? AppStrings.removeAdsHint
          : AppStrings.coinsPackHint;

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              product.kind == StoreProductKind.removeAds
                  ? Icons.block_rounded
                  : Icons.monetization_on_rounded,
              size: 22,
              color: product.kind == StoreProductKind.removeAds
                  ? AppColors.chalkMuted
                  : AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(product),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  owned ? AppStrings.removeAdsActive : _hint(product),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: owned ? AppColors.gold : AppColors.chalkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (owned)
            Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 24)
          else
            // الحدّ الأقصى يمنع سعراً طويلاً («1,99 €» مع خط كبير) من دفع
            // اسم المنتج خارج الصف.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: _MoneyButton(
                label: product.price,
                onPressed: busy ? null : () => _buy(context),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<PurchasesProvider>().buy(product.kind);

    final message = switch (outcome) {
      PurchaseOutcome.purchased => AppStrings.purchaseDone,
      PurchaseOutcome.pending => AppStrings.purchasePending,
      // إغلاق النافذة اختيار من اللاعب، لا خطأ يستحق رسالة.
      PurchaseOutcome.cancelled => null,
      PurchaseOutcome.failed || PurchaseOutcome.unavailable =>
        AppStrings.purchaseFailed,
    };
    if (message == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// زر السعر بالمال — بشكل زر السعر بالعملات نفسه، بنصّ المتجر بدل الرقم.
class _MoneyButton extends StatelessWidget {
  const _MoneyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled ? AppColors.pitchDark : AppColors.chalkMuted;

    return Material(
      color: enabled ? null : Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.goldGradient : null,
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// استعادة المشتريات بعد إعادة تثبيت أو على جهاز جديد.
class _RestoreRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => _restore(context),
        child: Text(
          AppStrings.restorePurchases,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.chalkMuted,
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final count = await context.read<PurchasesProvider>().restore();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? AppStrings.purchasesRestored
                : AppStrings.noPurchasesToRestore,
          ),
        ),
      );
  }
}

class _Item extends StatelessWidget {
  const _Item({
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
    return Surface(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chalkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PriceButton(
                price: price,
                onPressed: enabled ? () => _buy(context) : null,
              ),
              // الزر المعطّل يقول لماذا — كان السبب لا يظهر إلا بعد شراء فاشل
              // لا يمكن الوصول إليه أصلاً.
              if (!enabled) ...[
                const SizedBox(height: 5),
                Text(
                  disabledReason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chalkMuted,
                  ),
                ),
              ],
            ],
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

/// زر السعر: ذهبي حين يكفي الرصيد، باهت حين لا يكفي.
class _PriceButton extends StatelessWidget {
  const _PriceButton({required this.price, required this.onPressed});

  final int price;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final foreground = enabled ? AppColors.pitchDark : AppColors.chalkMuted;

    return Material(
      color: enabled ? null : Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.goldGradient : null,
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // يُصغَّر السعر في الزر الضيّق بدل أن يفيض مع الخطوط الكبيرة.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$price',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.4),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.chalkMuted, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.chalkMuted,
              ),
            ),
          ),
          Text(
            AppStrings.comingSoon,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.chalkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
