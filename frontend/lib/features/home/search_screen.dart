import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';

/// Search across the *whole* local congress catalogue, not just Day 1.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.openFiltersOnStart = false});
  final bool openFiltersOnStart;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _SearchGroup { all, sessions, speakers, resources }

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  _SearchGroup _group = _SearchGroup.all;
  CongressDay? _day;
  SessionTrack? _track;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQuery);
    if (widget.openFiltersOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFilters();
      });
    }
  }

  void _onQuery() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onQuery);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _matches(String text) =>
      text.toLowerCase().contains(_controller.text.trim().toLowerCase());

  List<CongressSession> get _sessions => CongressCatalog.sessions.where((s) {
    if (_day != null && s.day != _day) return false;
    if (_track != null && s.track != _track) return false;
    return _controller.text.trim().isEmpty ||
        _matches('${s.title} ${s.summary} ${s.location} ${s.trackLabel} '
            '${CongressCatalog.speakerName(s)}');
  }).toList();

  List<CongressSpeaker> get _speakers =>
      CongressCatalog.listedSpeakers.where((speaker) =>
        _controller.text.trim().isEmpty ||
        _matches('${speaker.fullName} ${speaker.title} ${speaker.country} '
            '${speaker.focusLabel} '
            '${CongressCatalog.sessionsForSpeaker(speaker.id).map((s) => s.title).join(' ')}')
      ).toList();

  List<CongressResource> get _resources =>
      CongressCatalog.resources.where((r) =>
        _controller.text.trim().isEmpty ||
        _matches('${r.title} ${r.subtitle} ${r.body} ${r.kindLabel}')
      ).toList();

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: StatefulBuilder(
          builder: (sheet, refresh) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search filters', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                const Text('Session day'),
                Wrap(spacing: 8, children: [
                  for (final item in <(CongressDay?, String)>[
                    (null, 'Both days'),
                    (CongressDay.day1, 'Day 1'),
                    (CongressDay.day2, 'Day 2')
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _day == item.$1,
                      onSelected: (_) { setState(() => _day = item.$1); refresh(() {}); },
                    ),
                ]),
                const SizedBox(height: 12),
                const Text('Session track'),
                Wrap(spacing: 8, children: [
                  for (final item in <(SessionTrack?, String)>[
                    (null, 'All tracks'),
                    (SessionTrack.keynote, 'Keynote'),
                    (SessionTrack.nutrition, 'Nutrition'),
                    (SessionTrack.research, 'Research'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _track == item.$1,
                      onSelected: (_) { setState(() => _track = item.$1); refresh(() {}); },
                    ),
                ]),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() { _day = null; _track = null; });
                        Navigator.pop(sheet);
                      },
                      child: const Text('Clear filters'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheet),
                      child: const Text('Show results'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final sessions = _sessions;
    final speakers = _speakers;
    final resources = _resources;
    final showSessions = _group == _SearchGroup.all || _group == _SearchGroup.sessions;
    final showSpeakers = _group == _SearchGroup.all || _group == _SearchGroup.speakers;
    final showResources = _group == _SearchGroup.all || _group == _SearchGroup.resources;
    final total = (showSessions ? sessions.length : 0) +
        (showSpeakers ? speakers.length : 0) +
        (showResources ? resources.length : 0);
    return CongressFeatureScaffold(
      title: 'Search Congress',
      titleAlign: TextAlign.start,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: TextField(
            autofocus: !widget.openFiltersOnStart,
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search sessions, speakers, topics...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                if (query.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  tooltip: 'Search filters',
                  onPressed: _openFilters,
                  icon: Icon(Icons.tune_rounded,
                    color: _day != null || _track != null
                        ? AppColors.accentBlue : AppColors.textSecondary),
                ),
              ]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        SizedBox(
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final group in _SearchGroup.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(switch(group) {
                      _SearchGroup.all => 'All',
                      _SearchGroup.sessions => 'Sessions',
                      _SearchGroup.speakers => 'Speakers',
                      _SearchGroup.resources => 'Resources',
                    }),
                    selected: _group == group,
                    onSelected: (_) => setState(() => _group = group),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Align(alignment: Alignment.centerLeft,
            child: Text('$total ${query.isEmpty ? 'catalogue items' : 'results'}',
              style: const TextStyle(color: AppColors.textSecondary))),
        ),
        Expanded(
          child: total == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 42, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('No matching items',
                            style: TextStyle(fontSize: 19,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Try another keyword, category or session filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _controller.clear();
                            _day = null;
                            _track = null;
                            _group = _SearchGroup.all;
                          }),
                          child: const Text('Clear all filters'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    if (showSessions && sessions.isNotEmpty) ...[
                      _SearchSectionLabel('Sessions', sessions.length),
                      for (final session in sessions)
                        _ResultCard(
                          key: ValueKey('session-${session.id}'),
                          icon: Icons.event_note_rounded,
                          heading: session.title,
                          supporting:
                              '${CongressCatalog.infoFor(session.day).shortLabel}  ·  '
                              '${session.timeLabel}  ·  '
                              '${CongressCatalog.speakerName(session)}',
                          onTap: () => context.push(
                            '${AppRoutes.agenda}?session=${session.id}',
                          ),
                        ),
                    ],
                    if (showSpeakers && speakers.isNotEmpty) ...[
                      _SearchSectionLabel('Speakers', speakers.length),
                      for (final speaker in speakers)
                        _ResultCard(
                          key: ValueKey('speaker-${speaker.id}'),
                          icon: Icons.person_outline_rounded,
                          heading: speaker.fullName,
                          supporting: '${speaker.title}  ·  ${speaker.country}',
                          onTap: () => context.push(
                            '${AppRoutes.speakers}?speaker=${speaker.id}',
                          ),
                        ),
                    ],
                    if (showResources && resources.isNotEmpty) ...[
                      _SearchSectionLabel('Resources', resources.length),
                      for (final resource in resources)
                        _ResultCard(
                          key: ValueKey('resource-${resource.id}'),
                          icon: Icons.description_outlined,
                          heading: resource.title,
                          supporting: resource.kindLabel,
                          onTap: () => context.push(
                            '${AppRoutes.resources}/view/${resource.id}',
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    super.key,
    required this.icon,
    required this.heading,
    required this.supporting,
    required this.onTap,
  });

  final IconData icon;
  final String heading;
  final String supporting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDE6F3)),
            ),
            child: Row(
              children: [
                Container(
                  height: 46, width: 46,
                  decoration: BoxDecoration(
                    color: AppColors.talkWash,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.iconBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(heading,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(supporting,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.iconBlue, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  const _SearchSectionLabel(this.title, this.count);
  final String title;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Row(children: [
      Text(title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.iconBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8)),
      const Spacer(),
      Text('$count',
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700)),
    ]),
  );
}
