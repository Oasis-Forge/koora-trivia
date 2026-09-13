import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';

/// شارة رصيد العملات.
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, this.onTap, this.compact = false});

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<EconomyProvider>().coins;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: compact ? 15 : 17,
            color: AppColors.gold,
          ),
          const SizedBox(width: 5),
          Text(
            '$coins',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: badge,
    );
  }
}
