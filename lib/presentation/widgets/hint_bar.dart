import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/economy_provider.dart';
import '../providers/quiz_provider.dart';

/// شريط المساعدات الثلاث داخل شاشة الاختبار.
///
/// يظهر في نمط المستويات فقط — اللعب السريع وتحدي اليوم بلا اقتصاد.
class HintBar extends StatelessWidget {
  const HintBar({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final economy = context.watch<EconomyProvider>();

    final playing = quiz.status == QuizStatus.playing;
    final enabled = playing && economy.hasHints;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _HintButton(
            icon: Icons.content_cut_rounded,
            label: AppStrings.hintFiftyFifty,
            enabled: enabled && !quiz.isFiftyFiftyUsed,
            onTap: () => _use(context, () => quiz.applyFiftyFifty()),
          ),
          const SizedBox(width: 8),
          _HintButton(
            icon: Icons.skip_next_rounded,
            label: AppStrings.hintSkip,
            enabled: enabled,
            onTap: () => _use(context, () => quiz.skipQuestion()),
          ),
          const SizedBox(width: 8),
          _HintButton(
            icon: Icons.more_time_rounded,
            label: AppStrings.hintExtraTime,
            enabled: enabled,
            onTap: () => _use(context, () => quiz.addExtraTime()),
          ),
          const SizedBox(width: 10),
          Text(
            '${economy.hintsLeft}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: economy.hasHints ? AppColors.gold : AppColors.chalkMuted,
            ),
          ),
          const Icon(
            Icons.lightbulb_rounded,
            size: 15,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }

  /// نستهلك المساعدة فقط إذا نجح تطبيقها فعلاً على السؤال.
  Future<void> _use(BuildContext context, bool Function() apply) async {
    final economy = context.read<EconomyProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (!economy.hasHints) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.noHintsLeft)));
      return;
    }

    if (!apply()) return;
    await economy.consumeHint();
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Material(
          color: enabled
              ? AppColors.cardSurface
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled ? AppColors.cardBorder : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                size: 19,
                color: enabled ? AppColors.gold : AppColors.chalkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
