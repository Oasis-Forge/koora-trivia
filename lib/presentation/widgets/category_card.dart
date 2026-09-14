import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/category_progress.dart';
import 'rows_card.dart';
import 'surface.dart';

/// بطاقة تصنيف في شبكة الاختيار: أيقونة ذهبية، الاسم، شريط تقدّم ذهبي،
/// والمستويات والنجوم أسفلها.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.progress,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final CategoryProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = progress.completedLevels;
    final total = progress.levelCount;
    final ratio = total == 0 ? 0.0 : done / total;
    final complete = progress.isFullyCompleted;

    return Surface(
      onTap: onTap,
      border: complete ? Border.all(color: AppColors.gold, width: 1.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (complete)
                Icon(Icons.verified_rounded, color: AppColors.gold, size: 18),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.gold, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          KooraProgress(value: ratio, gold: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$done / $total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.chalkMuted,
                ),
              ),
              const Spacer(),
              Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                '${progress.totalStars}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
