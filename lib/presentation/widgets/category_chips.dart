import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';

/// شريط فئات اللعب السريع. المختارة بتدرّج ذهبي، والبقية بحدّ رفيع.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<Category> categories;

  /// `null` تعني كل التصنيفات.
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <Category?>[null, ...categories];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = items[i];
          final selected = category?.slug == selectedSlug;

          return _Chip(
            label: category?.name ?? AppStrings.allCategories,
            selected: selected,
            onTap: () => onSelected(category?.slug),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(999);

    return Semantics(
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.8),
                    blurRadius: 14,
                    spreadRadius: -8,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: selected ? null : Colors.white.withValues(alpha: 0.04),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: selected
                ? BorderSide.none
                : BorderSide(color: AppColors.cardBorder, width: 1.4),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: selected ? AppColors.goldGradient : null,
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          selected ? FontWeight.w900 : FontWeight.w700,
                      color: selected ? AppColors.pitchDark : AppColors.chalk,
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
