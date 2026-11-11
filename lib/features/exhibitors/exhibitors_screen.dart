import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/light_sheet.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';

class ExhibitorsScreen extends StatelessWidget {
  const ExhibitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exhibitors = CongressCatalog.exhibitors;

    return CongressFeatureScaffold(
      title: 'Exhibitors',
      hero: const CongressHeroBanner(
        icon: Icons.work_outline_rounded,
        title: 'Demo booths',
        subtitle: 'Illustrative booths',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          for (final exhibitor in exhibitors) ...[
            _ExhibitorCard(
              exhibitor: exhibitor,
              onTap: () => _showExhibitor(context, exhibitor),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _showExhibitor(
    BuildContext context,
    CongressExhibitor exhibitor,
  ) {
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
                    'ILLUSTRATIVE',
                    style: TextStyle(
                      color: AppColors.categoryInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exhibitor.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${exhibitor.hall} · ${exhibitor.focus}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exhibitor.summary,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.4,
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

class _ExhibitorCard extends StatelessWidget {
  const _ExhibitorCard({required this.exhibitor, required this.onTap});

  final CongressExhibitor exhibitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              const GradientIconBadge(
                icon: Icons.storefront_outlined,
                size: 48,
                iconSize: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ILLUSTRATIVE',
                      style: TextStyle(
                        color: AppColors.categoryInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      exhibitor.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${exhibitor.hall} · ${exhibitor.focus}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
