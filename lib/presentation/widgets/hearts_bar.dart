import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';
import 'rewarded_button.dart';

/// شارة القلوب مع الوقت المتبقي للقلب التالي.
class HeartsBar extends StatelessWidget {
  const HeartsBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final empty = !economy.hasHearts;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: (empty ? AppColors.wrong : AppColors.cardSurface)
            .withValues(alpha: empty ? 0.18 : 1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: empty ? AppColors.wrong : AppColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            empty ? Icons.heart_broken_rounded : Icons.favorite_rounded,
            size: compact ? 15 : 17,
            color: empty ? AppColors.wrong : AppColors.wrong,
          ),
          const SizedBox(width: 5),
          Text(
            '${economy.hearts}/${economy.maxHearts}',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
              color: AppColors.chalk,
            ),
          ),
          if (!compact && economy.untilNextHeart != null) ...[
            const SizedBox(width: 8),
            Text(
              _format(economy.untilNextHeart!),
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.chalkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes;
    if (minutes >= 60) return '${d.inHours} س';
    return '${minutes < 1 ? 1 : minutes} د';
  }
}

/// حوار يظهر عند محاولة بدء مستوى بلا قلوب.
class NoHeartsDialog extends StatelessWidget {
  const NoHeartsDialog({super.key, required this.untilNext});

  final Duration? untilNext;

  static Future<void> show(BuildContext context, Duration? untilNext) {
    return showDialog<void>(
      context: context,
      builder: (_) => NoHeartsDialog(untilNext: untilNext),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      title: Row(
        children: [
          const Icon(Icons.heart_broken_rounded, color: AppColors.wrong),
          const SizedBox(width: 8),
          const Text(AppStrings.noHeartsTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.noHeartsBody, style: TextStyle(height: 1.6)),
          if (untilNext != null) ...[
            const SizedBox(height: 12),
            Text(
              '${AppStrings.nextHeartIn} ${HeartsBar._format(untilNext!)}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Builder(
            builder: (context) {
              final economy = context.watch<EconomyProvider>();
              return RewardedButton(
                label: AppStrings.watchAdForHeart,
                icon: Icons.favorite_rounded,
                dailyLimitReached: economy.rewardedRefillsLeft <= 0,
                onEarned: () async {
                  await context.read<EconomyProvider>().grantRewardedHearts();
                  if (context.mounted) Navigator.of(context).pop();
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.quitCancel),
        ),
      ],
    );
  }
}
