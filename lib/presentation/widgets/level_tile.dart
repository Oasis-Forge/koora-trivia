import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'star_row.dart';

enum LevelState { locked, available, completed }

/// مربّع مستوى واحد داخل شبكة المستويات.
class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.level,
    required this.state,
    required this.stars,
    required this.isSelected,
    required this.onTap,
  });

  final int level;
  final LevelState state;
  final int stars;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = state == LevelState.locked;

    final Color background;
    final Color border;
    final Color foreground;

    switch (state) {
      case LevelState.locked:
        background = Colors.white.withValues(alpha: 0.04);
        border = AppColors.cardBorder;
        foreground = AppColors.chalkMuted;
      case LevelState.available:
        background = AppColors.pitchLight.withValues(alpha: 0.22);
        border = AppColors.pitchLight;
        foreground = AppColors.chalk;
      case LevelState.completed:
        background = AppColors.cardSurface;
        border = AppColors.gold.withValues(alpha: 0.55);
        foreground = AppColors.chalk;
    }

    final shape = BorderRadius.circular(16);

    return Semantics(
      label: AppStrings.levelLabel(level),
      enabled: !locked,
      selected: isSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: background,
          borderRadius: shape,
          border: Border.all(
            color: isSelected ? AppColors.gold : border,
            width: isSelected ? 2.2 : 1,
          ),
          // حلقة ذهبية باهتة حول المستوى المختار.
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (locked)
                    Icon(Icons.lock_rounded, size: 20, color: foreground)
                  else ...[
                    Text(
                      '$level',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StarRow(earned: stars, size: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
