import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/category_progress.dart';

/// بطاقة تصنيف في شبكة الاختيار، تعرض التقدّم ونسبة الإنجاز.
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: complete ? AppColors.gold : AppColors.cardBorder,
              width: complete ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.gold, size: 21),
                  ),
                  const Spacer(),
                  if (complete)
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    complete ? AppColors.gold : AppColors.pitchLight,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$done / $total',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.chalkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${progress.totalStars}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.chalkMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
