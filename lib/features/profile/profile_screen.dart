import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/demo_limitation_sheet.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/widgets/light_sheet.dart';
import '../auth/domain/attendee.dart';
import '../auth/state/auth_controller.dart';
import '../congress/data/congress_catalog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendee = AuthScope.of(context).attendee;

    return CongressFeatureScaffold(
      title: 'My Profile',
      titleAlign: TextAlign.start,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
      safeAreaBottom: false,
      onBack: () => context.go(AppRoutes.home),
      leading: CongressHeaderButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        outlined: true,
        onPressed: () => context.go(AppRoutes.home),
      ),
      trailing: CongressHeaderButton(
        icon: Icons.settings_outlined,
        tooltip: 'Settings',
        outlined: true,
        onPressed: () => _showSessionSheet(context),
      ),
      hero: attendee == null ? null : _ProfileIdentity(attendee: attendee),
      body: attendee == null
          ? const Center(
              child: Text(
                'No attendee session.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _ContactCard(attendee: attendee),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.calendar_month_rounded,
                        value: CongressCatalog.sessions.length
                            .toString()
                            .padLeft(2, '0'),
                        label: 'Sessions',
                        onTap: () => context.push(AppRoutes.agenda),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.bookmark_rounded,
                        value: '00',
                        label: 'Saved',
                        onTap: () => showDemoLimitationSheet(
                          context,
                          title: 'Saved items',
                          message:
                              'Bookmarks are kept on each screen, not on this profile.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.workspace_premium_outlined,
                        value: '00',
                        label: 'Certificates',
                        onTap: () => showDemoLimitationSheet(
                          context,
                          title: 'Certificates',
                          message: 'This demo does not issue certificates.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _OrganizationDetail(organization: attendee.organization),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => AuthScope.of(context).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: BorderSide(
                        color: AppColors.navy.withValues(alpha: 0.28),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showSessionSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return LightSheet(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Settings are not connected. Sign out ends this session.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        final auth = AuthScope.of(context);
                        Navigator.pop(context);
                        auth.signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.attendee});

  final Attendee attendee;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              InitialsAvatar(
                initials: attendee.initials,
                size: 124,
                featured: true,
                fillColor: AppColors.talkWash,
                initialsColor: AppColors.iconBlue,
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showDemoLimitationSheet(
                      context,
                      title: 'Profile editing is not connected',
                      message: 'Photo updates are not available.',
                    ),
                    child: Ink(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.navyDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          attendee.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          attendee.role,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A4C9C).withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(color: AppColors.gold, width: 1.4),
            ),
            child: Text(
              'ID: ${attendee.id}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.attendee});

  final Attendee attendee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: attendee.email,
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: attendee.phone,
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),
          _ContactRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: attendee.location,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
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

class _OrganizationDetail extends StatelessWidget {
  const _OrganizationDetail({required this.organization});

  final String organization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Organization',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            organization,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECF4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.iconBlue, size: 26),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
