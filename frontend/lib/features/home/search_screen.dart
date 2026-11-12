import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../agenda/widgets/session_detail_sheet.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import '../speakers/widgets/speaker_detail_sheet.dart';

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
                Row(children: [
                  TextButton(
                    onPressed: () {
                      setState(() { _day = null; _track = null; });
                      Navigator.pop(sheet);
                    },
                    child: const Text('Clear filters'),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: () => Navigator.pop(sheet),
                    child: const Text('Show results')),
                ]),
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
              ? const Center(child: Text('No matching congress items. Try a different term.'))
              : ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
                  children: [
                    if (showSessions && sessions.isNotEmpty) ...[
                      const _SearchSectionLabel('Sessions'),
                      for (final s in sessions)
                        ListTile(
                          leading: const Icon(Icons.calendar_month_outlined),
                          title: Text(s.title),
                          subtitle: Text('${s.timeLabel} · ${CongressCatalog.speakerName(s)}'),
                          onTap: () => showSessionDetailSheet(context, session: s),
                        ),
                    ],
                    if (showSpeakers && speakers.isNotEmpty) ...[
                      const _SearchSectionLabel('Speakers'),
                      for (final s in speakers)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(s.fullName),
                          subtitle: Text(s.title),
                          onTap: () => showSpeakerDetailSheet(context, speaker: s),
                        ),
                    ],
                    if (showResources && resources.isNotEmpty) ...[
                      const _SearchSectionLabel('Resources'),
                      for (final r in resources)
                        ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(r.title),
                          subtitle: Text(r.kindLabel),
                          onTap: () => context.push('${AppRoutes.resources}/view/${r.id}'),
                        ),
                    ],
                  ]),
        ),
      ]),
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  const _SearchSectionLabel(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
    child: Text(title.toUpperCase(), style: const TextStyle(
      color: AppColors.iconBlue, fontWeight: FontWeight.w800,
      letterSpacing: 0.7, fontSize: 12)),
  );
}
