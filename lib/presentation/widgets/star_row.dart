import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';

/// صف نجوم من ثلاث، المملوءة منها بعدد [earned].
class StarRow extends StatelessWidget {
  static const int _total = 3;

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
    // قارئ الشاشة يقرأ «نجمتان من 3» بدل ثلاث أيقونات بلا اسم.
    return Semantics(
      label: AppStrings.starsLabel(
        ArabicCount.format(earned, ArabicNoun.star),
        _total,
      ),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= _total; i++)
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
      ),
    );
  }
}
