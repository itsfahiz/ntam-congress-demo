import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/congress_hero_banner.dart';
import '../../core/widgets/demo_limitation_sheet.dart';
import '../../core/widgets/light_search_field.dart';
import '../../core/widgets/light_sheet.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _searchController = TextEditingController();
  final _savedIds = <String>{};
  ResourceKind? _kind;
  var _savedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CongressResource> get _visible {
    return CongressCatalog.filterResources(
      kind: _kind,
      query: _searchController.text,
      savedIds: _savedIds,
      savedOnly: _savedOnly,
    );
  }

  void _openResource(CongressResource resource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return LightSheet(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.kindLabel,
                      style: const TextStyle(
                        color: AppColors.categoryInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      resource.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      resource.availabilityLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resource.body,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final resources = _visible;

    return CongressFeatureScaffold(
      title: 'Resources',
      trailing: CongressGoldHeaderButton(
        icon: Icons.folder_outlined,
        tooltip: 'About this library',
        onPressed: () => showDemoLimitationSheet(
          context,
          title: 'Demo library only',
          message:
              'These cards open on-device summaries. The app does not download files, open external URLs, or claim that PDFs and videos are bundled.',
        ),
      ),
      hero: const CongressHeroBanner(
        icon: Icons.cloud_download_outlined,
        title: 'Congress Library',
        subtitle: 'Access presentations, documents and media files',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: LightSearchField(
              controller: _searchController,
              hintText: 'Search resources',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: CongressFilterChips<String>(
              selected: _savedOnly ? 'saved' : (_kind?.name ?? 'all'),
              onSelected: (value) => setState(() {
                switch (value) {
                  case 'saved':
                    _savedOnly = true;
                    _kind = null;
                  case 'pdf':
                    _savedOnly = false;
                    _kind = ResourceKind.pdf;
                  case 'slides':
                    _savedOnly = false;
                    _kind = ResourceKind.slides;
                  case 'video':
                    _savedOnly = false;
                    _kind = ResourceKind.video;
                  default:
                    _savedOnly = false;
                    _kind = null;
                }
              }),
              options: const [
                FilterChipOption(value: 'all', label: 'All'),
                FilterChipOption(value: 'pdf', label: 'PDF'),
                FilterChipOption(value: 'slides', label: 'Slides'),
                FilterChipOption(value: 'video', label: 'Videos'),
                FilterChipOption(value: 'saved', label: 'Saved'),
              ],
            ),
          ),
          Expanded(
            child: resources.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No resources match your search or filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: resources.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final resource = resources[index];
                      return _ResourceCard(
                        resource: resource,
                        saved: _savedIds.contains(resource.id),
                        onOpen: () => _openResource(resource),
                        onSave: () => setState(() {
                          if (!_savedIds.add(resource.id)) {
                            _savedIds.remove(resource.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.saved,
    required this.onOpen,
    required this.onSave,
  });

  final CongressResource resource;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final palette = switch (resource.kind) {
      ResourceKind.pdf => (
        wash: const Color(0xFFFFE8E6),
        ink: const Color(0xFFD64545),
        icon: Icons.picture_as_pdf_rounded,
      ),
      ResourceKind.slides => (
        wash: AppColors.ceremonyWash,
        ink: AppColors.categoryInk,
        icon: Icons.slideshow_rounded,
      ),
      ResourceKind.video => (
        wash: AppColors.talkWash,
        ink: AppColors.iconBlue,
        icon: Icons.play_circle_outline_rounded,
      ),
    };

    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.wash,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(palette.icon, color: palette.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.kindLabel,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      resource.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      resource.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.availabilityLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: saved
                        ? 'Remove from saved'
                        : 'Save on this device',
                    onPressed: onSave,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? AppColors.gold : AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Open demo summary',
                    onPressed: onOpen,
                    icon: const Icon(
                      Icons.download_rounded,
                      color: AppColors.iconBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
