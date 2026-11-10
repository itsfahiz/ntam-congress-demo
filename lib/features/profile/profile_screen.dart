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
      lightBody: false,
      safeAreaBottom: false,
      onBack: () => context.go(AppRoutes.home),
      trailing: CongressHeaderButton(
        icon: Icons.settings_outlined,
        tooltip: 'Demo session',
        onPressed: () => _showSessionSheet(context),
      ),
      body: attendee == null
          ? const Center(
              child: Text(
                'No attendee session.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InitialsAvatar(
                        initials: attendee.initials,
                        size: 108,
                        featured: true,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Material(
                          color: AppColors.gold,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => showDemoLimitationSheet(
                              context,
                              title: 'Profile editing is not connected',
                              message:
                                  'This assessment app does not upload photos or sync profile changes.',
                            ),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(color: AppColors.gold),
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
                const SizedBox(height: 22),
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
                          title: 'Saved items stay on each screen',
                          message:
                              'Agenda bookmarks and speaker favorites are in-memory on those screens. This profile does not keep a saved count.',
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
                          title: 'No certificates in this demo',
                          message:
                              'This assessment app does not issue or store certificates.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'This profile is a local demo session. It does not sync to a Nestlé account and clears when you sign out or restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => AuthScope.of(context).signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.45),
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
                    'Demo session',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Settings, password changes and account security are not connected. Sign out only clears the in-memory attendee session.',
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

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.attendee});

  final Attendee attendee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(24),
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
            icon: Icons.business_outlined,
            label: 'Organization',
            value: attendee.organization,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.iconBlue),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
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
