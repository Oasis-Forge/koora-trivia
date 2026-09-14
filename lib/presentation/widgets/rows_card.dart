import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'surface.dart';

/// عنوان قسم ذهبي فوق بطاقة أو شبكة.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// بطاقة صفوف: كل صف بأيقونة ذهبية واسم وقيمة، وبينها خطوط فاصلة.
class RowsCard extends StatelessWidget {
  const RowsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// صف داخل `RowsCard`.
class KooraRow extends StatelessWidget {
  const KooraRow({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData? icon;

  /// قيمة نصية في نهاية الصف (تُتجاهل إذا مُرّر `trailing`).
  final String? value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: AppColors.gold),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.chalkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.chalk,
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// شريط تقدّم رفيع — أخضر للمهام، ذهبي لتقدّم التصنيفات.
class KooraProgress extends StatelessWidget {
  const KooraProgress({super.key, required this.value, this.gold = false});

  /// من 0 إلى 1.
  final double value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: 0.14)),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gold ? AppColors.goldGradient : null,
                  color: gold ? null : AppColors.correct,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
