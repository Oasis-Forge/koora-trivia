import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../providers/economy_provider.dart';
import '../screens/shop_screen.dart';
import 'surface.dart';

/// شارة رصيد العملات — حبّة ذهبية بارتفاع 48 تفتح المتجر من أي شاشة.
///
/// كانت تبدو زراً ولا تعمل إلا في الرئيسية؛ ومع بيع العملات صار «+» ولمسها
/// الطريق الطبيعي إلى المتجر. في المتجر نفسه تبقى رصيداً فقط.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, this.opensShop = true});

  final bool opensShop;

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<EconomyProvider>().coins;

    return Semantics(
      button: opensShop,
      label: opensShop
          ? AppStrings.coinsOpenShop(
              ArabicCount.format(coins, ArabicNoun.coin),
            )
          : null,
      excludeSemantics: opensShop,
      child: StatusPill(
        icon: Icons.monetization_on_rounded,
        iconColor: AppColors.gold,
        label: '$coins',
        labelColor: AppColors.gold,
        trailingIcon: opensShop ? Icons.add_circle_rounded : null,
        onTap: opensShop
            ? () => Navigator.of(context).pushNamed(ShopScreen.routeName)
            : null,
      ),
    );
  }
}
