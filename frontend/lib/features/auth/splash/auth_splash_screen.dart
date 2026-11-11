import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/congress_background.dart';

class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navyDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CongressBackground(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NESTLÉ MEDICAL CONGRESS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'NESTLÉ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 0.92,
                          letterSpacing: 2.4,
                        ),
                      ),
                      Text(
                        'CONGRESS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 0.86,
                          letterSpacing: 2.4,
                        ),
                      ),
                      SizedBox(height: 28),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
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
