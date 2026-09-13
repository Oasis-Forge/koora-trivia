import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';

/// عدّاد دائري للوقت المتبقي، يتحول للأحمر في آخر خمس ثوانٍ.
class TimerRing extends StatelessWidget {
  const TimerRing({super.key, required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final fraction = (secondsLeft / AppConfig.secondsPerQuestion).clamp(0.0, 1.0);
    final danger = secondsLeft <= 5;
    final color = danger ? AppColors.wrong : AppColors.gold;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: fraction, end: fraction),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
