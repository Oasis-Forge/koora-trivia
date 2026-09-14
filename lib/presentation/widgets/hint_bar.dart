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
    final available = playing && economy.hasHints;

    // سبب التعطيل يظهر عند لمس الزر — كان الزر المعطّل لا يقول لماذا. لا سبب بعد
    // كشف الإجابة، فالتعطيل حينها واضح.
    String? reason({bool usedOnThisQuestion = false, String? usedReason}) {
      if (!playing) return null;
      if (!economy.hasHints) return AppStrings.noHintsLeft;
      return usedOnThisQuestion ? usedReason : null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _HintButton(
            icon: Icons.content_cut_rounded,
            label: AppStrings.hintFiftyFifty,
            enabled: available && !quiz.isFiftyFiftyUsed,
            disabledReason: reason(
              usedOnThisQuestion: quiz.isFiftyFiftyUsed,
              usedReason: AppStrings.hintFiftyFiftyUsed,
            ),
            onTap: () => _use(context, () => quiz.applyFiftyFifty()),
          ),
          const SizedBox(width: 8),
          _HintButton(
            icon: Icons.skip_next_rounded,
            label: AppStrings.hintSkip,
            enabled: available,
            disabledReason: reason(),
            onTap: () => _use(context, () => quiz.skipQuestion()),
          ),
          const SizedBox(width: 8),
          _HintButton(
            icon: Icons.more_time_rounded,
            label: AppStrings.hintExtraTime,
            enabled: available && !quiz.isExtraTimeUsed,
            disabledReason: reason(
              usedOnThisQuestion: quiz.isExtraTimeUsed,
              usedReason: AppStrings.hintExtraTimeUsed,
            ),
            onTap: () => _use(context, () => quiz.addExtraTime()),
          ),
          const SizedBox(width: 12),
          Text(
            '${economy.hintsLeft}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: economy.hasHints ? AppColors.gold : AppColors.chalkMuted,
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            Icons.lightbulb_rounded,
            size: 16,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }

  /// نستهلك المساعدة فقط إذا نجح تطبيقها فعلاً على السؤال.
  Future<void> _use(BuildContext context, bool Function() apply) async {
    final economy = context.read<EconomyProvider>();
    if (!economy.hasHints || !apply()) return;
    await economy.consumeHint();
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.disabledReason,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  /// يُعرض عند لمس الزر المعطّل؛ `null` يعني أن اللمس لا يفعل شيئاً.
  final String? disabledReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reason = disabledReason;

    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: Colors.white.withValues(alpha: enabled ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled
                ? onTap
                : reason == null
                    ? null
                    : () => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(reason))),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled ? AppColors.cardBorder : Colors.transparent,
                ),
              ),
              // الاسم تحت الأيقونة: الأيقونات وحدها لم تكن مفهومة للاعب الجديد.
              // يُصغَّر المحتوى ولا يفيض إن كبّر اللاعب خط النظام.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? AppColors.gold : AppColors.chalkMuted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.chalk : AppColors.chalkMuted,
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
