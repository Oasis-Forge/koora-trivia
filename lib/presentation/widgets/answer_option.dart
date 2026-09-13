import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// زر خيار الإجابة — يتلوّن بالأخضر/الأحمر بعد الكشف عن الإجابة.
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
  });

  final String label;
  final int index;
  final bool revealed;
  final bool isCorrect;
  final bool isSelected;

  /// أزالته مساعدة "حذف إجابتين".
  final bool isEliminated;

  final VoidCallback? onTap;

  static const List<String> _letters = ['أ', 'ب', 'ج', 'د'];

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.cardSurface;
    Color border = AppColors.cardBorder;
    IconData? trailing;

    if (revealed) {
      if (isCorrect) {
        background = AppColors.correct.withValues(alpha: 0.22);
        border = AppColors.correct;
        trailing = Icons.check_circle_rounded;
      } else if (isSelected) {
        background = AppColors.wrong.withValues(alpha: 0.20);
        border = AppColors.wrong;
        trailing = Icons.cancel_rounded;
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isEliminated ? 0.28 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: revealed ? 1.8 : 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      index < _letters.length
                          ? _letters[index]
                          : '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.chalk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Icon(
                      trailing,
                      color: isCorrect ? AppColors.correct : AppColors.wrong,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
