import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/arabic_count.dart';
import '../../domain/entities/daily_task.dart';
import '../providers/economy_provider.dart';
import '../widgets/coin_badge.dart';
import '../widgets/pitch_background.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const String routeName = '/tasks';

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.chalk,
                    ),
                    const Expanded(
                      child: Text(
                        AppStrings.tasks,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const CoinBadge(),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    for (final task in economy.tasks) ...[
                      _TaskCard(task: task),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    _Chest(
                      ready: economy.chestReady,
                      opened: economy.chestClaimed,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      AppStrings.tasksResetHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chalkMuted,
                      ),
                    ),
                  ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: task.isClaimable ? AppColors.gold : AppColors.cardBorder,
          width: task.isClaimable ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _title(task),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${task.reward}',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: task.ratio,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.isComplete
                              ? AppColors.correct
                              : AppColors.pitchLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${task.progress} / ${task.target}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.chalkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: FilledButton(
                  onPressed: task.isClaimable
                      ? () => _claim(context, task.kind)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    backgroundColor: AppColors.gold,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.07),
                    disabledForegroundColor: AppColors.chalkMuted,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(
                    task.claimed ? AppStrings.claimed : AppStrings.claim,
                  ),
                ),
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

class _Chest extends StatelessWidget {
  const _Chest({required this.ready, required this.opened});

  final bool ready;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          opened ? AppStrings.chestOpened : AppStrings.chestHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: opened ? AppColors.gold : AppColors.chalkMuted,
            fontWeight: opened ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        Icon(
          opened
              ? Icons.card_giftcard_rounded
              : ready
                  ? Icons.inventory_2_rounded
                  : Icons.lock_rounded,
          size: 62,
          color: ready || opened
              ? AppColors.gold
              : Colors.white.withValues(alpha: 0.22),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 160,
          child: FilledButton(
            onPressed: ready ? () => _open(context) : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.07),
              disabledForegroundColor: AppColors.chalkMuted,
            ),
            child: const Text(AppStrings.openChest),
          ),
        ),
      ],
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
