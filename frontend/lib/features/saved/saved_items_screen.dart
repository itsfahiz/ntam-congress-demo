import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../agenda/widgets/session_detail_sheet.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import '../speakers/widgets/speaker_detail_sheet.dart';
import 'state/saved_items_controller.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  int _selectedTab = 0;

  Future<void> _remove(SavedItemsController saved, String type, String id) async {
    try {
      await saved.toggle(type, id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _showResource(CongressResource resource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.kindLabel,
                    style: const TextStyle(
                      color: AppColors.categoryInk,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 8),
                Text(resource.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 8),
                Text(resource.availabilityLabel),
                const SizedBox(height: 14),
                Text(resource.body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = SavedItemsScope.of(context);
    final sessions = CongressCatalog.sessions
        .where((session) => saved.isSaved('session', session.id))
        .toList();
    final resources = CongressCatalog.resources
        .where((resource) => saved.isSaved('resource', resource.id))
        .toList();
    final speakers = CongressCatalog.listedSpeakers
        .where((speaker) => saved.isSaved('speaker', speaker.id))
        .toList();

    return CongressFeatureScaffold(
      title: 'Saved Items',
      leading: CongressHeaderButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        outlined: true,
        onPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Sessions (${sessions.length})'),
                    selected: _selectedTab == 0,
                    onSelected: (_) => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Resources (${resources.length})'),
                    selected: _selectedTab == 1,
                    onSelected: (_) => setState(() => _selectedTab = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Speakers (${speakers.length})'),
                    selected: _selectedTab == 2,
                    onSelected: (_) => setState(() => _selectedTab = 2),
                  ),
                ],
              ),
            ),
          ),
          if (saved.isLoading) const LinearProgressIndicator(),
          if (saved.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(saved.error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => saved.reload(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedTab == 0
                ? sessions.isEmpty
                    ? const Center(child: Text('No saved sessions yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today_outlined),
                              title: Text(session.title),
                              subtitle: Text(
                                '${session.timeLabel} · ${session.location}',
                              ),
                              onTap: () => showSessionDetailSheet(
                                context,
                                session: session,
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove saved session',
                                icon: const Icon(Icons.bookmark_remove_outlined),
                                onPressed: () =>
                                    _remove(saved, 'session', session.id),
                              ),
                            ),
                          );
                        },
                      )
                : _selectedTab == 1
                    ? resources.isEmpty
                        ? const Center(child: Text('No saved resources yet.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: resources.length,
                            itemBuilder: (context, index) {
                              final resource = resources[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(resource.title),
                                  subtitle: Text(resource.availabilityLabel),
                                  onTap: () => _showResource(resource),
                                  trailing: IconButton(
                                    tooltip: 'Remove saved resource',
                                    icon: const Icon(Icons.bookmark_remove_outlined),
                                    onPressed: () =>
                                        _remove(saved, 'resource', resource.id),
                                  ),
                                ),
                              );
                            },
                          )
                    : speakers.isEmpty
                        ? const Center(child: Text('No favorite speakers yet.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: speakers.length,
                            itemBuilder: (context, index) {
                              final speaker = speakers[index];
                              final sessions = CongressCatalog.sessionsForSpeaker(speaker.id);
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.star_rounded),
                                  title: Text(speaker.fullName),
                                  subtitle: Text(
                                    sessions.isEmpty
                                        ? speaker.title
                                        : sessions.map((item) => item.title).join(', '),
                                  ),
                                  onTap: () => showSpeakerDetailSheet(
                                    context,
                                    speaker: speaker,
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Remove favorite speaker',
                                    icon: const Icon(Icons.star_outline_rounded),
                                    onPressed: () =>
                                        _remove(saved, 'speaker', speaker.id),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
