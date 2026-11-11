import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Stylized preview only. No map SDK, coordinates, or network tiles.
class StaticVenueMap extends StatelessWidget {
  const StaticVenueMap({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 220,
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
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.navyDeep,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Map Preview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
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
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8F2FF),
    );

    final wash = Paint()..color = const Color(0xFFD7E8FF);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.78), 96, wash);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.18), 78, wash);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final across = Path()
      ..moveTo(-12, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.52,
        size.width + 12,
        size.height * 0.4,
      );
    canvas.drawPath(across, road);

    final down = Path()
      ..moveTo(size.width * 0.12, -12)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.48,
        size.width * 0.82,
        size.height + 12,
      );
    canvas.drawPath(down, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
