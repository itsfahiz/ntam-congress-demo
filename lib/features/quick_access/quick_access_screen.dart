import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/widgets/congress_feature_scaffold.dart';
import '../../core/widgets/congress_filter_chips.dart';
import '../../core/widgets/gradient_icon_badge.dart';
import '../../core/widgets/light_search_field.dart';
import '../congress/data/congress_catalog.dart';
import '../congress/domain/congress_models.dart';
import 'widgets/quick_access_card.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({super.key});

  @override
  State<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends State<QuickAccessScreen> {
  final _searchController = TextEditingController();
  QuickAccessCategory? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QuickAccessItem> get _visibleItems {
    return CongressCatalog.filterQuickAccess(
      category: _category,
      query: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;

    return CongressFeatureScaffold(
      title: 'Quick Access',
      trailing: const _GoldGridMark(),
      hero: const _ExploreBanner(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: LightSearchField(
              controller: _searchController,
              hintText: 'Search quick access',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: CongressFilterChips<QuickAccessCategory>(
              selected: _category,
              onSelected: (value) => setState(() => _category = value),
              options: const [
                FilterChipOption(value: null, label: 'All'),
                FilterChipOption(
                  value: QuickAccessCategory.event,
                  label: 'Event',
                ),
                FilterChipOption(
                  value: QuickAccessCategory.interactive,
                  label: 'Interactive',
                ),
                FilterChipOption(
                  value: QuickAccessCategory.tools,
                  label: 'Tools',
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyShortcuts()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 198,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return QuickAccessCard(
                        key: ValueKey(item.route),
                        item: item,
                        onTap: () => context.push(item.route),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoldGridMark extends StatelessWidget {
  const _GoldGridMark();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: AppColors.gold,
      shape: CircleBorder(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.grid_view_rounded, color: AppColors.navyDeep),
      ),
    );
  }
}

class _ExploreBanner extends StatelessWidget {
  const _ExploreBanner();

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
            icon: Icons.auto_awesome_rounded,
            size: 52,
            iconSize: 26,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Congress Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Everything you need for the full event experience',
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

class _EmptyShortcuts extends StatelessWidget {
  const _EmptyShortcuts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No shortcuts match your search or filter.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }
}
