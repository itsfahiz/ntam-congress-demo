import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_background.dart';
import '../../core/widgets/light_sheet.dart';
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
  final _searchController = TextEditingController();
  SessionTrack? _trackFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CongressSession> get _visibleSessions {
    final query = _searchController.text.trim().toLowerCase();
    return CongressCatalog.filterSessions(
      day: CongressDay.day1,
      track: _trackFilter,
      query: query,
    );
  }

  Future<void> _pickFilter() async {
    final result = await showModalBottomSheet<_FilterChoice>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return LightSheet(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Filter upcoming sessions',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                for (final option in _sessionFilterOptions)
                  ListTile(
                    title: Text(option.label),
                    trailing: _trackFilter == option.track
                        ? const Icon(Icons.check, color: AppColors.accentBlue)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() => _trackFilter = result.track);
  }

  Future<void> _showNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return LightSheet(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      'Congress notices',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final notice in HomeMockData.notifications)
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.iconBlue,
                      ),
                      title: Text(notice.title),
                      subtitle: Text(notice.body),
                      onTap: () {
                        Navigator.pop(context);
                        context.push(notice.route);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendee = AuthScope.of(context).attendee;
    final sessions = _visibleSessions;

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
                          onBellPressed: _showNotifications,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: HomeSearchBar(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onFilterPressed: _pickFilter,
                          filterActive: _trackFilter != null,
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(child: FeaturedEventCard()),
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
                          title: 'Upcoming Sessions',
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
