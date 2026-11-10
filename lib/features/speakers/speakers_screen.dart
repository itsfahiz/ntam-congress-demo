import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/light_search_field.dart';
import '../../core/widgets/light_sheet.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import 'widgets/speaker_card.dart';
import 'widgets/speaker_detail_sheet.dart';

class SpeakersScreen extends StatefulWidget {
  const SpeakersScreen({super.key});

  @override
  State<SpeakersScreen> createState() => _SpeakersScreenState();
}

class _SpeakersScreenState extends State<SpeakersScreen> {
  final _searchController = TextEditingController();
  final _favoriteIds = <String>{};
  SpeakerFocus? _focus;
  var _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CongressSpeaker> get _visibleSpeakers {
    return CongressCatalog.filterSpeakers(
      focus: _focus,
      query: _searchController.text,
      favoriteIds: _favoriteIds,
      favoritesOnly: _favoritesOnly,
    );
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (!_favoriteIds.add(id)) {
        _favoriteIds.remove(id);
      }
    });
  }

  Future<void> _pickFocus() async {
    final result = await showModalBottomSheet<FilterChipOption<SpeakerFocus>>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return LightSheet(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in _focusOptions)
                  ListTile(
                    title: Text(option.label),
                    trailing: _focus == option.value
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
    setState(() => _focus = result.value);
  }

  @override
  Widget build(BuildContext context) {
    final speakers = _visibleSpeakers;

    return CongressFeatureScaffold(
      title: 'Speakers',
      trailing: CongressGoldHeaderButton(
        icon: _favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
        tooltip: _favoritesOnly ? 'Show all speakers' : 'Show favorites',
        onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
      ),
      hero: const _ExpertsBanner(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: LightSearchField(
                    controller: _searchController,
                    hintText: 'Search speakers',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: _focus != null
                      ? AppColors.navyChip
                      : AppColors.searchFill,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickFocus,
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.tune_rounded,
                        color: _focus != null
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: CongressFilterChips<SpeakerFocus>(
              selected: _focus,
              onSelected: (value) => setState(() => _focus = value),
              options: _focusOptions,
            ),
          ),
          Expanded(
            child: speakers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No speakers match your search or filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: speakers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final speaker = speakers[index];
                      return SpeakerCard(
                        speaker: speaker,
                        favorite: _favoriteIds.contains(speaker.id),
                        onTap: () =>
                            showSpeakerDetailSheet(context, speaker: speaker),
                        onFavorite: () => _toggleFavorite(speaker.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

const _focusOptions = <FilterChipOption<SpeakerFocus>>[
  FilterChipOption(value: null, label: 'All'),
  FilterChipOption(value: SpeakerFocus.nutrition, label: 'Nutrition'),
  FilterChipOption(value: SpeakerFocus.research, label: 'Research'),
  FilterChipOption(value: SpeakerFocus.pediatrics, label: 'Pediatrics'),
];

class _ExpertsBanner extends StatelessWidget {
  const _ExpertsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          GradientIconBadge(
            icon: Icons.groups_outlined,
            size: 52,
            iconSize: 26,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Global Medical Experts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Meet speakers from nutrition, research and healthcare',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
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
