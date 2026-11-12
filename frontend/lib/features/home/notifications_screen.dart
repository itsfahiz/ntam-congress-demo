import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import 'data/home_mock_data.dart';

/// Demonstration programme notices. These are not push notifications or live alerts.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CongressFeatureScaffold(
      title: 'Notifications',
      titleAlign: TextAlign.start,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text('CONGRESS UPDATES', style: TextStyle(
            fontWeight: FontWeight.w800, color: AppColors.iconBlue,
            fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('Programme notices',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 6),
          const Text(
            'These are illustrative congress notices, not live push alerts.',
            style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          for (final notice in HomeMockData.notifications)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.talkWash,
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.iconBlue)),
                title: Text(notice.title, style:
                  const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(notice.body)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(notice.route),
              ),
            ),
        ],
      ),
    );
  }
}
