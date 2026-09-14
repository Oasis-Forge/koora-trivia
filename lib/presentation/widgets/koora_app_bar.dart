import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'surface.dart';

/// زر دائري بارتفاع 48 على سطح البطاقة: رجوع، إغلاق، إعدادات.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Surface(
          radius: 999,
          padding: EdgeInsets.zero,
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 21, color: AppColors.chalk),
          ),
        ),
      ),
    );
  }
}

/// شريط أعلى الشاشة: زر الرجوع في البداية، العنوان وسطر تحته، وحبّات في النهاية.
class KooraAppBar extends StatelessWidget {
  const KooraAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          RoundIconButton(
            // في العربية يشير سهم الرجوع إلى اليمين.
            icon: Icons.arrow_back_rounded,
            tooltip: AppStrings.back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.chalkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final item in trailing) ...[const SizedBox(width: 8), item],
        ],
      ),
    );
  }
}
