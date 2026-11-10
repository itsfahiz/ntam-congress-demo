import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import 'congress_background.dart';
import 'light_sheet.dart';

class CongressFeatureScaffold extends StatelessWidget {
  const CongressFeatureScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.hero,
    this.lightBody = true,
  });

  final String title;
  final Widget body;
  final Widget? trailing;
  final Widget? hero;
  final bool lightBody;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CongressBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxContentWidth,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            _HeaderButton(
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Back',
                              onPressed: () => context.pop(),
                            ),
                            Expanded(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            trailing ?? const SizedBox(width: 48, height: 48),
                          ],
                        ),
                      ),
                      if (hero != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: hero,
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: lightBody
                            ? DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  child: LightSheet(child: body),
                                ),
                              )
                            : body,
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

class CongressGoldHeaderButton extends StatelessWidget {
  const CongressGoldHeaderButton({
    super.key,
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
        color: AppColors.gold,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppColors.navyDeep),
          ),
        ),
      ),
    );
  }
}

class CongressHeaderButton extends StatelessWidget {
  const CongressHeaderButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.foreground = Colors.white,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return _HeaderButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      foreground: foreground,
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.foreground = Colors.white,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? 'Action',
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: foreground),
          ),
        ),
      ),
    );
  }
}
