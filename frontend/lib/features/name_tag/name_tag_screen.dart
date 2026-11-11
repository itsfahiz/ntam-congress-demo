import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/demo_limitation_sheet.dart';
import '../../core/widgets/initials_avatar.dart';
import '../auth/state/auth_controller.dart';
import '../congress/data/congress_catalog.dart';
import 'data/badge_qr_repository.dart';

class NameTagScreen extends StatefulWidget {
  const NameTagScreen({super.key});

  @override
  State<NameTagScreen> createState() => _NameTagScreenState();
}

class _NameTagScreenState extends State<NameTagScreen> {
  String? _requestedFor;
  String? _verifyUrl;
  String? _error;
  var _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final attendee = AuthScope.of(context).attendee;
    if (attendee == null) return;
    if (_requestedFor == attendee.id) return;
    _requestedFor = attendee.id;
    _loading = true;
    _error = null;
    _verifyUrl = null;
    final repository = BadgeQrScope.of(context);
    repository
        .issueVerifyUrl()
        .then((url) {
          if (!mounted || _requestedFor != attendee.id) return;
          setState(() {
            _verifyUrl = url;
            _loading = false;
          });
        })
        .catchError((Object error) {
          if (!mounted || _requestedFor != attendee.id) return;
          setState(() {
            _error = error is BadgeQrException
                ? error.message
                : 'Could not load your verification badge.';
            _loading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final attendee = AuthScope.of(context).attendee;

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
                            _VerificationQr(
                              verifyUrl: _verifyUrl,
                              loading: _loading,
                              error: _error,
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

class _VerificationQr extends StatelessWidget {
  const _VerificationQr({
    required this.verifyUrl,
    required this.loading,
    required this.error,
  });

  final String? verifyUrl;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: loading
              ? 'Loading attendee verification QR code'
              : error != null
              ? 'Could not load attendee verification QR code'
              : 'Attendee verification QR code',
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
                  child: SizedBox(
                    width: 196,
                    height: 196,
                    child: _body(),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          error ??
              (loading ? 'Loading verification code' : 'Scan to verify attendee'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    final url = verifyUrl;
    if (error != null || url == null || url.isEmpty) {
      return const Center(
        child: Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: AppColors.textSecondary,
        ),
      );
    }
    return QrImageView(
      key: ValueKey<String>(url),
      data: url,
      size: 196,
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppColors.navyDeep,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppColors.navyDeep,
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
