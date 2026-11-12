import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/light_sheet.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import '../saved/state/saved_items_controller.dart';
import 'widgets/speaker_card.dart';
import 'widgets/speaker_detail_sheet.dart';

class SpeakersScreen extends StatefulWidget {
  const SpeakersScreen({super.key, this.initialSpeakerId});

  final String? initialSpeakerId;

  @override
  State<SpeakersScreen> createState() => _SpeakersScreenState();
}

class _SpeakersScreenState extends State<SpeakersScreen> {
  final _searchController = TextEditingController();
  SpeakerFocus? _focus;
  var _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    final targetId = widget.initialSpeakerId;
    if (targetId == null) return;
    for (final speaker in CongressCatalog.listedSpeakers) {
      if (speaker.id != targetId) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSpeakerDetailSheet(context, speaker: speaker);
      });
      break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CongressSpeaker> _visibleSpeakers(Set<String> favoriteIds) {
    return CongressCatalog.filterSpeakers(
      focus: _focus,
      query: _searchController.text,
      favoriteIds: favoriteIds,
      favoritesOnly: _favoritesOnly,
    );
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      await SavedItemsScope.of(context).toggle('speaker', id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
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
    final saved = SavedItemsScope.of(context);
    final speakers = _visibleSpeakers(saved.idsFor('speaker'));

    return CongressFeatureScaffold(
      title: 'Speakers',
      titleAlign: TextAlign.start,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
      leading: CongressHeaderButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        outlined: true,
        onPressed: () => context.pop(),
      ),
      trailing: CongressHeaderButton(
        icon: _favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
        tooltip: _favoritesOnly ? 'Show all speakers' : 'Show favorites',
        outlined: true,
        foreground: AppColors.gold,
        onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
      ),
      hero: const CongressHeroBanner(
        icon: Icons.groups_outlined,
        title: 'Global Medical\nExperts',
        subtitle: 'Meet speakers from nutrition, research and healthcare',
        padding: EdgeInsets.fromLTRB(18, 22, 18, 22),
        titleSize: 24,
        titleWeight: FontWeight.w900,
        badgeSize: 56,
        titleSpacing: 8,
        contentSpacing: 16,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _SpeakersSearchBar(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onFilterPressed: _pickFocus,
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: speakers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final speaker = speakers[index];
                      return SpeakerCard(
                        speaker: speaker,
                        favorite: saved.isSaved('speaker', speaker.id),
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

class _SpeakersSearchBar extends StatelessWidget {
  const _SpeakersSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilterPressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: const Color(0xFFD0D7E4)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.accentBlue,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search speakers',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Filter speakers',
            onPressed: onFilterPressed,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.tune_rounded, color: AppColors.iconBlue),
          ),
        ],
      ),
    );
  }
}
