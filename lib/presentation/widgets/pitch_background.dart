import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// خلفية ملعب كرة قدم: تدرّج عشبي + خطوط مجزوزة + دائرة المنتصف.
class PitchBackground extends StatelessWidget {
  const PitchBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.pitchGradient),
      child: CustomPaint(
        painter: _PitchPainter(),
        child: child,
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // خطوط العشب المجزوز.
    final stripePaint = Paint()..color = AppColors.pitchStripe;
    const stripeCount = 9;
    final stripeHeight = size.height / stripeCount;
    for (var i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        stripePaint,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // دائرة المنتصف وخط المنتصف.
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.42),
      size.width * 0.28,
      linePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.42),
      Offset(size.width, size.height * 0.42),
      linePaint,
    );

    // منطقة الجزاء السفلية.
    final boxWidth = size.width * 0.62;
    canvas.drawRect(
      Rect.fromLTWH(
        (size.width - boxWidth) / 2,
        size.height - size.height * 0.16,
        boxWidth,
        size.height * 0.20,
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
