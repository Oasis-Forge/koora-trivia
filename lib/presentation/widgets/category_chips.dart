import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';

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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = items[i];
          final isActive = category?.slug == selectedSlug;

          return ChoiceChip(
            label: Text(category?.name ?? AppStrings.allCategories),
            selected: isActive,
            onSelected: (_) => onSelected(category?.slug),
            showCheckmark: false,
            backgroundColor: AppColors.cardSurface,
            selectedColor: AppColors.gold,
            labelStyle: TextStyle(
              color: isActive ? AppColors.pitchDark : AppColors.chalk,
              fontWeight: FontWeight.w700,
            ),
            side: const BorderSide(color: AppColors.cardBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}
