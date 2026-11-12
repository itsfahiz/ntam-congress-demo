import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_background.dart';
import '../assistant/widgets/congress_ai_home_entry.dart';
import '../auth/domain/attendee.dart';
import '../auth/state/auth_controller.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import 'data/home_mock_data.dart';
import 'widgets/featured_event_card.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/quick_access_grid.dart';
import 'widgets/upcoming_session_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openSearch() => context.push(AppRoutes.search);
  void _openNotifications() => context.push(AppRoutes.notifications);

  @override
  Widget build(BuildContext context) {
    final attendee = AuthScope.of(context).attendee;
    final sessions = CongressCatalog.sessions
        .where((session) => session.day == CongressDay.day1)
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CongressBackground(),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.maxContentWidth,
                ),
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _HomeHeader(
                          attendee: attendee,
                          hasNotices: HomeMockData.notifications.isNotEmpty,
                          onBellPressed: _openNotifications,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: HomeSearchBar(
                          onSearchTap: _openSearch,
                          onFilterPressed: _openSearch,
                          filterActive: false,
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(child: FeaturedEventCard()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: CongressAiHomeEntry(
                          onTap: () => context.push(AppRoutes.assistant),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Quick Access',
                          actionLabel: 'View All',
                          onAction: () => context.push(AppRoutes.quickAccess),
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(child: QuickAccessGrid()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: 'Day 1 Programme',
                          actionLabel: 'View All',
                          onAction: () => context.push(AppRoutes.agenda),
                        ),
                      ),
                    ),
                    if (sessions.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'No sessions match your search or filter.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                        sliver: SliverList.separated(
                          itemCount: sessions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return UpcomingSessionTile(
                              session: sessions[index],
                              onTap: () => context.push(AppRoutes.agenda),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChoice {
  const _FilterChoice(this.label, this.track);

  final String label;
  final SessionTrack? track;
}

const _sessionFilterOptions = [
  _FilterChoice('All tracks', null),
  _FilterChoice('Keynote', SessionTrack.keynote),
  _FilterChoice('Nutrition', SessionTrack.nutrition),
  _FilterChoice('Research', SessionTrack.research),
];

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.attendee,
    required this.hasNotices,
    required this.onBellPressed,
  });

  final Attendee? attendee;
  final bool hasNotices;
  final VoidCallback onBellPressed;

  @override
  Widget build(BuildContext context) {
    final name = attendee?.fullName ?? 'Attendee';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NESTLÉ MEDICAL CONGRESS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            Material(
              color: Colors.white.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBellPressed,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                      if (hasNotices)
                        const Positioned(
                          top: 10,
                          right: 11,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.notice,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 8, height: 8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Welcome Back,\n'),
              TextSpan(text: '$name '),
              const TextSpan(text: '👋'),
            ],
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.8),
            visualDensity: VisualDensity.compact,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: TextStyle(
                  color: AppColors.gradientEnd.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.gradientEnd.withValues(alpha: 0.95),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
