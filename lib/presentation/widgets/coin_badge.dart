import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';
import 'surface.dart';

/// شارة رصيد العملات — حبّة ذهبية بارتفاع 48 مثل بقية الحبّات.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<EconomyProvider>().coins;

    return StatusPill(
      icon: Icons.monetization_on_rounded,
      iconColor: AppColors.gold,
      label: '$coins',
      labelColor: AppColors.gold,
      onTap: onTap,
    );
  }
}
