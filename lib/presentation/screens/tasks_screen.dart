import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/daily_task.dart';
import '../providers/economy_provider.dart';
import '../widgets/coin_badge.dart';
import '../widgets/koora_app_bar.dart';
import '../widgets/koora_buttons.dart';
import '../widgets/pitch_background.dart';
import '../widgets/rows_card.dart';
import '../widgets/surface.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const String routeName = '/tasks';

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              KooraAppBar(
                title: AppStrings.tasks,
                trailing: [CoinBadge()],
              ),
              const SizedBox(height: 16),
              for (final task in economy.tasks) ...[
                _TaskCard(task: task),
                const SizedBox(height: 12),
              ],
              _Chest(ready: economy.chestReady, opened: economy.chestClaimed),
              const SizedBox(height: 16),
              Text(
                AppStrings.tasksResetHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chalkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final DailyTask task;

  static String _title(DailyTask task) => switch (task.kind) {
        TaskKind.correctAnswers => AppStrings.taskAnswers(
            ArabicCount.format(
              task.target,
              ArabicNoun.correctAnswer,
              object: true,
            ),
          ),
        TaskKind.completeDaily => AppStrings.taskDaily,
        TaskKind.completeLevel => AppStrings.taskLevel,
      };

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title(task),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _RewardPill(reward: task.reward),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KooraProgress(value: task.ratio),
                    const SizedBox(height: 6),
                    Text(
                      '${task.shownProgress} / ${task.target}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.chalkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ClaimButton(
                label: task.claimed ? AppStrings.claimed : AppStrings.claim,
                onPressed: task.isClaimable
                    ? () => _claim(context, task.kind)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context, TaskKind kind) async {
    final messenger = ScaffoldMessenger.of(context);
    final reward = await context.read<EconomyProvider>().claimTask(kind);
    if (reward <= 0) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('+$reward 🪙')));
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.reward});

  final int reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            '$reward',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// زر «استلم»: ذهبي حين تكتمل المهمة، باهت قبلها وبعد الاستلام.
class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ready = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: ready
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.9),
                  blurRadius: 18,
                  spreadRadius: -12,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: ready ? null : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: ready ? AppColors.goldGradient : null,
          ),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ready ? AppColors.pitchDark : AppColors.chalkMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chest extends StatelessWidget {
  const _Chest({required this.ready, required this.opened});

  final bool ready;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final lit = ready || opened;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: lit
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              opened
                  ? Icons.card_giftcard_rounded
                  : ready
                      ? Icons.inventory_2_rounded
                      : Icons.lock_rounded,
              size: 32,
              color: lit ? AppColors.gold : AppColors.chalkMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            opened ? AppStrings.chestOpened : AppStrings.chestHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: opened ? AppColors.gold : AppColors.chalkMuted,
            ),
          ),
          const SizedBox(height: 12),
          GoldButton(
            label: AppStrings.openChest,
            icon: Icons.card_giftcard_rounded,
            onPressed: ready ? () => _open(context) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final reward = await context.read<EconomyProvider>().claimChest();
    if (reward <= 0) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('+$reward 🪙')));
  }
}
