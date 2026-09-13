import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// صف نجوم من ثلاث، المملوءة منها بعدد [earned].
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.earned,
    this.size = 14,
    this.dimmed = false,
  });

  final int earned;
  final double size;

  /// يخفت اللون حين يكون المستوى مقفلاً.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              i <= earned ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i <= earned
                  ? (dimmed ? AppColors.chalkMuted : AppColors.gold)
                  : Colors.white.withValues(alpha: 0.22),
            ),
          ),
      ],
    );
  }
}
