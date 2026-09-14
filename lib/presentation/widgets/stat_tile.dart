import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String value;
  final String label;

  /// ذهبي المظهر الحالي إن لم يُمرَّر — القيمة الافتراضية لا تكون من مظهر متغيّر.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppColors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.chalk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.chalkMuted),
          ),
        ],
      ),
    );
  }
}
