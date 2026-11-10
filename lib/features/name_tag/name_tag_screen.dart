import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/demo_limitation_sheet.dart';
import '../../core/widgets/initials_avatar.dart';
import '../auth/state/auth_controller.dart';
import '../congress/data/congress_catalog.dart';
import 'demo_badge_qr.dart';

class NameTagScreen extends StatelessWidget {
  const NameTagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendee = AuthScope.of(context).attendee;
    final payload = attendee == null ? '' : DemoBadgeQr.payloadFor(attendee);

    return CongressFeatureScaffold(
      title: 'My Name Tag',
      lightBody: false,
      trailing: CongressGoldHeaderButton(
        icon: Icons.print_rounded,
        tooltip: 'Print',
        onPressed: () => showDemoLimitationSheet(
          context,
          title: 'Printing is not connected',
          message:
              'This assessment app does not send the badge to a printer or share sheet.',
        ),
      ),
      body: attendee == null
          ? const Center(
              child: Text(
                'No attendee session.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryButton,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                            bottom: Radius.circular(18),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'NESTLÉ MEDICAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'CONGRESS 2026',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                        child: Column(
                          children: [
                            InitialsAvatar(
                              initials: attendee.initials,
                              size: 96,
                              featured: true,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              attendee.fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${attendee.organization} · ${attendee.role}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _BadgeRow(
                              icon: Icons.badge_outlined,
                              label: 'Badge ID',
                              value: attendee.id,
                            ),
                            const SizedBox(height: 10),
                            _BadgeRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: attendee.location,
                            ),
                            const SizedBox(height: 10),
                            _BadgeRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Congress Date',
                              value: CongressCatalog.venue.dateLabel,
                            ),
                            const SizedBox(height: 20),
                            Semantics(
                              label: 'Demo badge QR code',
                              child: ColoredBox(
                                color: Colors.white,
                                child: QrImageView(
                                  key: ValueKey(payload),
                                  data: payload,
                                  size: 196,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.navyDeep,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: AppColors.navyDeep,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Demo badge QR. Not connected to check-in or verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.searchFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.iconBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
