import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/light_sheet.dart';
import '../../congress/data/congress_catalog.dart';
import '../../congress/domain/congress_models.dart';

Future<void> showSpeakerDetailSheet(
  BuildContext context, {
  required CongressSpeaker speaker,
}) {
  final sessions = CongressCatalog.sessionsForSpeaker(speaker.id);
  final parentContext = context;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return LightSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(
                        initials: speaker.initials,
                        featured: speaker.featured,
                        size: 72,
                        fillColor: AppColors.fieldIconWash,
                        initialsColor: AppColors.iconBlue,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              speaker.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              speaker.title,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    speaker.country,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    speaker.bio,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sessions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final session in sessions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(session.title),
                      subtitle: Text(
                        '${CongressCatalog.infoFor(session.day).shortLabel} · ${session.timeLabel} · ${session.location}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(context);
                        parentContext.push('${AppRoutes.agenda}?session=${session.id}');
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
