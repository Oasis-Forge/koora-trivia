import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';

/// بطاقة تحدي اليوم — تعرض حالة التحدي والسلسلة والوقت المتبقي للتحدي التالي.
class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({
    super.key,
    required this.isDone,
    required this.streak,
    required this.untilNext,
    required this.onPlay,
  });

  final bool isDone;
  final int streak;
  final Duration untilNext;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDone
              ? [AppColors.pitchMid, AppColors.pitchDeep]
              : [AppColors.gold, AppColors.goldDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDone ? AppColors.cardBorder : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDone ? Colors.black : AppColors.gold)
                .withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.verified_rounded : Icons.local_fire_department,
                color: isDone ? AppColors.gold : AppColors.pitchDark,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.dailyChallenge,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDone ? AppColors.chalk : AppColors.pitchDark,
                ),
              ),
              const Spacer(),
              _StreakBadge(streak: streak, onGold: !isDone),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isDone
                ? '${AppStrings.dailyDone}  •  التحدي القادم بعد ${_format(untilNext)}'
                : '${ArabicCount.format(AppConfig.dailyQuestionCount, ArabicNoun.question)} • نقاط مضاعفة ×${AppConfig.dailyMultiplier}',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDone
                  ? AppColors.chalkMuted
                  : AppColors.pitchDark.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isDone ? null : onPlay,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDone ? AppColors.cardSurface : AppColors.pitchDark,
                foregroundColor: isDone ? AppColors.chalkMuted : AppColors.gold,
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.18),
                disabledForegroundColor: AppColors.chalkMuted,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: Icon(isDone ? Icons.check_rounded : Icons.play_arrow_rounded),
              label: Text(isDone ? AppStrings.dailyDone : AppStrings.dailyReady),
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h س و $m د';
    return '$m د';
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak, required this.onGold});

  final int streak;
  final bool onGold;

  @override
  Widget build(BuildContext context) {
    final fg = onGold ? AppColors.pitchDark : AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (onGold ? AppColors.pitchDark : AppColors.gold)
            .withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.whatshot_rounded, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}
