import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'star_row.dart';
import '../../core/constants/app_strings.dart';

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

    return Semantics(
      label: AppStrings.levelLabel(level),
      enabled: !locked,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.gold : border,
                width: isSelected ? 2.2 : 1.3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked)
                  Icon(
                    Icons.lock_rounded,
                    size: 19,
                    color: foreground.withValues(alpha: 0.7),
                  )
                else
                  Text(
                    '$level',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: foreground,
                    ),
                  ),
                const SizedBox(height: 4),
                if (!locked)
                  StarRow(earned: stars, size: 11)
                else
                  const SizedBox(height: 11),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
