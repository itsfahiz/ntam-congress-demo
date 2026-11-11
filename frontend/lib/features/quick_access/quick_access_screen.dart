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
      leading: _OutlinedSquareButton(
        icon: Icons.chevron_left_rounded,
        tooltip: 'Back',
        onPressed: () => context.pop(),
      ),
      trailing: const _GoldGridMark(),
      hero: const _ExploreBanner(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: LightSearchField(
              controller: _searchController,
              hintText: 'Search quick access',
              fillColor: AppColors.fieldFill,
              borderColor: const Color(0xFFD0D7E4),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: CongressFilterChips<QuickAccessCategory>(
              selected: _category,
              selectedFill: AppColors.accentBlue,
              unselectedForeground: AppColors.mutedLabel,
              unselectedWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 206,
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

class _OutlinedSquareButton extends StatelessWidget {
  const _OutlinedSquareButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _GoldGridMark extends StatelessWidget {
  const _GoldGridMark();

  @override
  Widget build(BuildContext context) {
    Widget tile() {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(1.6),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [tile(), tile()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [tile(), tile()],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreBanner extends StatelessWidget {
  const _ExploreBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        children: [
          GradientIconBadge(
            icon: Icons.auto_awesome_rounded,
            size: 56,
            iconSize: 28,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Congress\nTools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Everything you need for the full event experience',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
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
