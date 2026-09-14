import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// خلفية ملعب كرة قدم: تدرّج عشبي، خطوط باهتة جداً، كرة كبيرة كعلامة مائية،
/// وإضاءة خفيفة من الأعلى (تصميم Claude Design، 14 سبتمبر 2026).
class PitchBackground extends StatelessWidget {
  const PitchBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.pitchGradient),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
              // كرة عملاقة شبه شفافة تكسر فراغ الأرضية دون أن تسحب النظر.
              Positioned(
                left: -140,
                top: constraints.maxHeight * 0.36,
                child: Icon(
                  Icons.sports_soccer,
                  size: 520,
                  color: Colors.white.withValues(alpha: 0.018),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 0.9,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.6],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  /// ارتفاع الشريط الواحد من العشب المجزوز.
  static const double _stripe = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()..color = AppColors.pitchStripe;
    for (var y = 0.0; y < size.height; y += _stripe * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, _stripe), stripePaint);
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // خط المنتصف ودائرته عند 42% من الارتفاع.
    final middle = size.height * 0.42;
    canvas.drawLine(Offset(0, middle), Offset(size.width, middle), linePaint);
    canvas.drawCircle(Offset(size.width / 2, middle), 94, linePaint);

    // منطقة الجزاء السفلية — مفتوحة من الأسفل خارج الشاشة.
    const boxWidth = 204.0;
    const boxHeight = 118.0;
    final left = (size.width - boxWidth) / 2;
    final top = size.height + 52 - boxHeight;
    canvas.drawPath(
      Path()
        ..moveTo(left, size.height)
        ..lineTo(left, top)
        ..lineTo(left + boxWidth, top)
        ..lineTo(left + boxWidth, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
