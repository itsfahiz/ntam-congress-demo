import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Stylized preview only. No map SDK, coordinates, or network tiles.
class StaticVenueMap extends StatelessWidget {
  const StaticVenueMap({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _MapPainter()),
            const Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.navyDeep,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 14,
              child: Text(
                'Map Preview',
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.mapWash;
    canvas.drawRect(Offset.zero & size, bg);

    final wash = Paint()..color = AppColors.mapDeep;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.75), 90, wash);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 70, wash);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.38),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.7, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
