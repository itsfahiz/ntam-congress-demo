import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Column (not Scaffold.bottomNavigationBar) so Home cannot paint under the tabs.
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Column(
        children: [
          Expanded(child: ClipRect(child: navigationShell)),
          Material(
            color: AppColors.navyDeep,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ShellTab(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: navigationShell.currentIndex == 0,
                          onTap: () => navigationShell.goBranch(0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ShellTab(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          selected: navigationShell.currentIndex == 1,
                          accented: true,
                          onTap: () => navigationShell.goBranch(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellTab extends StatelessWidget {
  const _ShellTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accented = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.gradientEnd;
    final radius = BorderRadius.circular(18);
    final selectedColor = accented ? accent : Colors.white;
    final fill = !selected
        ? Colors.transparent
        : accented
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fill,
            border: Border.all(
              color: selected && accented ? accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? selectedColor
                    : Colors.white.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? selectedColor
                      : Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
