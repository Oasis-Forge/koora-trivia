import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// سطح البطاقات في التصميم الجديد: لون البطاقة، حدّ رفيع، لمعة أعلاها وظل ناعم.
///
/// كل بطاقة وحبّة (`StatusPill`) تمرّ من هنا، فتبقى العمق واللمعة متطابقة في كل
/// الشاشات ومع كل المظاهر.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// لون مخالف للون البطاقة الافتراضي (بطاقة الصندوق مثلاً).
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: color ?? AppColors.cardSurface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: border == null
              ? BorderSide(color: AppColors.cardBorder)
              : BorderSide.none,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: AppColors.surfaceHighlight,
            border: border,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: shape,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// حبّة حالة: القلوب، العملات، النجوم، أو زر مختصر بجانب العنوان.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
    this.iconAtEnd = false,
  });

  final IconData icon;
  final String label;

  /// سطر صغير بعد الرقم، مثل وقت القلب التالي.
  final String? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  /// الأيقونة بعد النص (زر «المهام اليومية» مثلاً).
  final bool iconAtEnd;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 18, color: iconColor ?? AppColors.gold);
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: labelColor ?? AppColors.chalk,
      ),
    );

    return Surface(
      radius: 999,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 48, // هدف لمس مريح في كل الحبّات.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!iconAtEnd) ...[iconWidget, const SizedBox(width: 7)],
            text,
            if (trailing != null) ...[
              const SizedBox(width: 7),
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chalkMuted,
                ),
              ),
            ],
            if (iconAtEnd) ...[const SizedBox(width: 7), iconWidget],
          ],
        ),
      ),
    );
  }
}
