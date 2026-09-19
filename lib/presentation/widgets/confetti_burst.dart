import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// قصاصات ملوّنة تتساقط مرة واحدة فوق الشاشة — لثلاث نجوم أو رقم قياسي جديد.
///
/// رسم بسيط بلا حزمة، لا يلتقط اللمس، ولا يظهر لمن أطفأ الحركة في هاتفه.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 70});

  final int pieces;

  static const Duration duration = Duration(milliseconds: 2600);

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: ConfettiBurst.duration)
        ..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _pieces = List.generate(widget.pieces, (_) => _Piece(random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return const SizedBox.shrink();
    }
    final colors = [
      AppColors.gold,
      AppColors.correct,
      AppColors.wrong,
      Colors.white,
    ];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _controller.isCompleted
            ? const SizedBox.shrink()
            : CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(_pieces, _controller.value, colors),
              ),
      ),
    );
  }
}

class _Piece {
  _Piece(Random random)
      : x = random.nextDouble(),
        delay = random.nextDouble() * 0.3,
        speed = 0.7 + random.nextDouble() * 0.6,
        drift = (random.nextDouble() - 0.5) * 0.25,
        spin = (random.nextDouble() - 0.5) * 12,
        size = 6 + random.nextDouble() * 6,
        color = random.nextInt(4);

  final double x;
  final double delay;
  final double speed;
  final double drift;
  final double spin;
  final double size;
  final int color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t, this.colors);

  final List<_Piece> pieces;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final dx = (p.x + p.drift * local) * size.width;
      final dy = -20 + local * p.speed * (size.height + 40);
      // تخفت في آخر الربع بدل أن تختفي فجأة.
      final fade = local > 0.75 ? (1 - local) / 0.25 : 1.0;
      paint.color = colors[p.color].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(p.spin * local)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
