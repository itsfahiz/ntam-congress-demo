import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      titleAlign: TextAlign.start,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
      lightBody: false,
      leading: CongressHeaderButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        outlined: true,
        onPressed: () => context.pop(),
      ),
      trailing: CongressHeaderButton(
        icon: Icons.print_rounded,
        tooltip: 'Print',
        outlined: true,
        foreground: AppColors.gold,
        onPressed: () => showDemoLimitationSheet(
          context,
          title: 'Printing is not connected',
          message: 'This app does not send the badge to a printer.',
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryButton,
                            borderRadius: BorderRadius.circular(20),
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
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        child: Column(
                          children: [
                            InitialsAvatar(
                              initials: attendee.initials,
                              size: 120,
                              featured: true,
                              fillColor: AppColors.fieldIconWash,
                              initialsColor: AppColors.iconBlue,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              attendee.fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${attendee.organization} · ${attendee.role}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _AwardDivider(),
                            const SizedBox(height: 20),
                            _BadgeRow(
                              icon: Icons.badge_outlined,
                              label: 'Badge ID',
                              value: attendee.id,
                            ),
                            const SizedBox(height: 12),
                            _BadgeRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: attendee.location,
                            ),
                            const SizedBox(height: 12),
                            _BadgeRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Congress Date',
                              value: CongressCatalog.venue.dateLabel,
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              label: 'Demo badge QR code',
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF1F6),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: QrImageView(
                                        key: ValueKey(payload),
                                        data: payload,
                                        size: 196,
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: AppColors.navyDeep,
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                              dataModuleShape:
                                                  QrDataModuleShape.square,
                                              color: AppColors.navyDeep,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Demo badge',
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

class _AwardDivider extends StatelessWidget {
  const _AwardDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.fieldBorder, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.gold,
            size: 18,
          ),
        ),
        Expanded(child: Divider(color: AppColors.fieldBorder, thickness: 1)),
      ],
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
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.talkWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.iconBlue, size: 22),
          ),
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
                const SizedBox(height: 2),
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
