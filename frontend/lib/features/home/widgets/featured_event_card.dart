import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../congress/data/congress_catalog.dart';

class FeaturedEventCard extends StatelessWidget {
  const FeaturedEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    final event = CongressCatalog.featuredEvent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => context.push(AppRoutes.agenda),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1C4A94).withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                child: const Text(
                  'DEMO EVENT',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title.replaceFirst(' of ', ' of\n'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 4),
                    child: _LotusMark(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${event.dateLabel}  ·  ${event.location}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotusMark extends StatelessWidget {
  const _LotusMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(painter: _LotusPainter()),
    );
  }
}

class _LotusPainter extends CustomPainter {
  const _LotusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final origin = Offset(size.width * 0.5, size.height * 0.84);

    void petal(double tilt, double length, double bulge) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(tilt);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-bulge, -length * 0.46, 0, -length)
        ..quadraticBezierTo(bulge, -length * 0.46, 0, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    petal(-0.74, size.height * 0.64, size.width * 0.22);
    petal(0.74, size.height * 0.64, size.width * 0.22);
    petal(0, size.height * 0.80, size.width * 0.20);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
