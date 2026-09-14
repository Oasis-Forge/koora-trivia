import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// أزرار التصميم الجديد. الأيقونة تُكتب بعد النص فتقع على يساره في العربية —
/// قاعدة صاحب التطبيق.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.decoration,
    required this.foreground,
    this.icon,
    this.sheen,
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final BoxDecoration decoration;
  final Color foreground;
  final IconData? icon;
  final Gradient? sheen;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final radius = decoration.borderRadius ?? BorderRadius.circular(18);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius as BorderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Ink(
              decoration: BoxDecoration(gradient: sheen),
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: fontWeight,
                        color: foreground,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(icon, size: 20, color: foreground),
                    ],
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

/// الزر الأساسي: تدرّج ذهبي مع وهج خفيف تحته.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return _ActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      height: 56,
      foreground: enabled ? AppColors.pitchDark : AppColors.chalkMuted,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled ? AppColors.goldGradient : null,
        color: enabled ? null : Colors.white.withValues(alpha: 0.07),
        boxShadow: enabled ? AppColors.goldButtonShadow : null,
      ),
      sheen: enabled ? AppColors.buttonSheen(0.3) : null,
    );
  }
}

/// الزر الثانوي البارز: تدرّج أخضر من لون الملعب.
class SolidButton extends StatelessWidget {
  const SolidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      height: 56,
      foreground: AppColors.chalk,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.solidGradient,
        boxShadow: AppColors.solidButtonShadow,
      ),
      sheen: AppColors.buttonSheen(0.16),
    );
  }
}

/// زر بحدّ رفيع على تعبئة شفافة.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      height: 52,
      foreground: AppColors.chalk,
      fontWeight: FontWeight.w800,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: AppColors.cardBorder, width: 1.4),
      ),
    );
  }
}
