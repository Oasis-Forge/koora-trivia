import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// زر خيار الإجابة — سطح بطاقة بلمعة وظل، ويتلوّن بالأخضر/الأحمر بعد الكشف.
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.label,
    required this.index,
    required this.revealed,
    required this.isCorrect,
    required this.isSelected,
    required this.onTap,
    this.isEliminated = false,
    this.compact = false,
  });

  final String label;
  final int index;
  final bool revealed;
  final bool isCorrect;
  final bool isSelected;

  /// أزالته مساعدة "حذف إجابتين".
  final bool isEliminated;

  /// مقاسات أصغر للشاشات القصيرة حتى تتسع الخيارات الأربعة دون تمرير.
  final bool compact;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.cardSurface;
    Color border = AppColors.cardBorder;
    IconData? trailing;
    var highlighted = false;

    if (revealed) {
      if (isCorrect) {
        background = AppColors.correct.withValues(alpha: 0.22);
        border = AppColors.correct;
        trailing = Icons.check_circle_rounded;
        highlighted = true;
      } else if (isSelected) {
        background = AppColors.wrong.withValues(alpha: 0.20);
        border = AppColors.wrong;
        trailing = Icons.cancel_rounded;
        highlighted = true;
      }
    }

    final badgeSize = compact ? 28.0 : 32.0;
    final shape = BorderRadius.circular(18);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isEliminated ? 0.28 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: EdgeInsets.only(bottom: compact ? 8 : 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: shape,
          border: Border.all(color: border, width: highlighted ? 1.8 : 1),
          boxShadow: AppColors.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: shape,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              // اللمعة على الخيارات العادية؛ الملوّنة بعد الكشف تبقى صريحة.
              gradient: highlighted ? null : AppColors.surfaceHighlight,
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: compact ? 11 : 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: compact ? 28 : 32),
                  child: Row(
                    children: [
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          index < AppStrings.optionLetters.length
                              ? AppStrings.optionLetters[index]
                              : '${index + 1}',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: compact ? 15 : 16,
                            height: 1.4,
                            color: AppColors.chalk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        Icon(
                          trailing,
                          color:
                              isCorrect ? AppColors.correct : AppColors.wrong,
                        ),
                    ],
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
