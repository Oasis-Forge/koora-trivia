import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// بطاقة تحدي اليوم — أبرز ما في الرئيسية: تدرّج ذهبي، لمعة، كرة باهتة،
/// والسلسلة في حبّة صغيرة (تصميم Claude Design).
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
    // بعد الإنجاز تهدأ البطاقة إلى ألوان الملعب فلا تنافس زر اللعب السريع.
    final onGold = !isDone;
    final title = onGold ? AppColors.pitchDark : AppColors.chalk;
    final body = onGold
        ? AppColors.pitchDark.withValues(alpha: 0.74)
        : AppColors.chalkMuted;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: onGold
            ? AppColors.goldGradient
            : LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [AppColors.pitchMid, AppColors.pitchDeep],
              ),
        border: onGold ? null : Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            spreadRadius: -14,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // لمعة من الزاوية العليا وكرة باهتة أسفل البطاقة.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.76, -1),
                  radius: 1.1,
                  colors: [
                    Colors.white.withValues(alpha: onGold ? 0.42 : 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.58],
                ),
              ),
            ),
          ),
          Positioned(
            left: -64,
            bottom: -70,
            child: Icon(
              Icons.sports_soccer,
              size: 250,
              color: (onGold ? AppColors.pitchDark : Colors.white)
                  .withValues(alpha: 0.09),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.dailyChallenge,
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StreakBadge(streak: streak, onGold: onGold),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.dailyMeta(
                    '${AppConfig.dailyMultiplier}',
                    _format(untilNext),
                  ),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: body,
                  ),
                ),
                const SizedBox(height: 16),
                _Cta(isDone: isDone, onPlay: onPlay),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return AppStrings.hoursMinutes(h, m);
    return AppStrings.minutesShort(m);
  }
}

/// زر البطاقة: داكن على الذهبي قبل اللعب، ومعطّل بعد الإنجاز.
class _Cta extends StatelessWidget {
  const _Cta({required this.isDone, required this.onPlay});

  final bool isDone;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final background = isDone
        ? Colors.black.withValues(alpha: 0.18)
        : AppColors.pitchDark;
    final foreground = isDone ? AppColors.chalkMuted : AppColors.gold;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDone ? null : onPlay,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isDone ? AppStrings.dailyDone : AppStrings.dailyStart,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isDone ? Icons.check_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
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
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: (onGold ? AppColors.pitchDark : AppColors.gold)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 16, color: fg),
          const SizedBox(width: 5),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
