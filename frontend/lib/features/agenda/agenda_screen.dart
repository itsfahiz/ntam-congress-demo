import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/light_search_field.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import '../saved/state/saved_items_controller.dart';
import 'widgets/agenda_day_selector.dart';
import 'widgets/agenda_session_card.dart';
import 'widgets/session_detail_sheet.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _searchController = TextEditingController();
  CongressDay _day = CongressDay.day1;
  SessionTrack? _track;
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CongressDayInfo get _dayInfo => CongressCatalog.infoFor(_day);

  List<CongressSession> get _visibleSessions {
    return CongressCatalog.filterSessions(
      day: _day,
      track: _track,
      query: _searchController.text,
    );
  }

  void _resetFilters() {
    setState(() {
      _day = CongressDay.day1;
      _track = null;
      _searchOpen = false;
      _searchController.clear();
    });
  }

  Future<void> _toggleBookmark(String id) async {
    try {
      await SavedItemsScope.of(context).toggle('session', id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _visibleSessions;
    final saved = SavedItemsScope.of(context);

    return CongressFeatureScaffold(
      title: 'Congress Agenda',
      leading: CongressHeaderButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        outlined: true,
        onPressed: () => context.pop(),
      ),
      trailing: CongressHeaderButton(
        icon: Icons.search_rounded,
        tooltip: 'Search',
        outlined: true,
        onPressed: () => setState(() => _searchOpen = !_searchOpen),
      ),
      hero: Column(
        children: [
          _ScheduleBanner(info: _dayInfo),
          const SizedBox(height: 14),
          AgendaDaySelector(
            selected: _day,
            onSelected: (day) => setState(() => _day = day),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's Sessions",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Material(
                  color: AppColors.talkWash,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  child: InkWell(
                    onTap: _resetFilters,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: AppColors.iconBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.iconBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: LightSearchField(
                controller: _searchController,
                hintText: 'Search sessions, speakers, halls',
                onChanged: (_) => setState(() {}),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: CongressFilterChips<SessionTrack>(
              selected: _track,
              selectedFill: AppColors.accentBlue,
              unselectedForeground: AppColors.mutedLabel,
              unselectedWeight: FontWeight.w600,
              onSelected: (value) => setState(() => _track = value),
              options: const [
                FilterChipOption(value: null, label: 'All'),
                FilterChipOption(value: SessionTrack.keynote, label: 'Keynote'),
                FilterChipOption(
                  value: SessionTrack.nutrition,
                  label: 'Nutrition',
                ),
                FilterChipOption(
                  value: SessionTrack.research,
                  label: 'Research',
                ),
              ],
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const _EmptySessions()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return AgendaSessionCard(
                        session: session,
                        bookmarked: saved.isSaved('session', session.id),
                        onTap: () =>
                            showSessionDetailSheet(context, session: session),
                        onBookmark: () => _toggleBookmark(session.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBanner extends StatelessWidget {
  const _ScheduleBanner({required this.info});

  final CongressDayInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C4A94).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.goldBadge,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.dateLong,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
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

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No sessions match this day, track or search.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}
