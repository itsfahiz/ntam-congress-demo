import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class CongressBackground extends StatelessWidget {
  const CongressBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.nightSky),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Glow(alignment: Alignment(-0.2, -1.05), diameter: 420),
          _Glow(alignment: Alignment(1.1, 0.85), diameter: 280),
          CustomPaint(painter: _DotGridPainter()),
          CustomPaint(painter: _ArcPainter()),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.alignment, required this.diameter});

  final Alignment alignment;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.navyGlow.withValues(alpha: 0.55),
                AppColors.navyGlow.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    const spacing = 18.0;
    const radius = 1.1;
    final maxX = size.width * 0.55;
    final maxY = size.height * 0.28;

    for (double y = 16; y < maxY; y += spacing) {
      for (double x = 12; x < maxX; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.06);

    final center = Offset(size.width * 0.78, size.height * 0.18);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 70.0 + (i * 42)),
        math.pi * 0.7,
        math.pi * 0.85,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
