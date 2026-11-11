import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../congress/data/congress_catalog.dart';
import '../../congress/domain/congress_models.dart';

class AgendaSessionCard extends StatelessWidget {
  const AgendaSessionCard({
    super.key,
    required this.session,
    required this.bookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  final CongressSession session;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(session.glyph);

    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: session.highlighted
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : AppColors.fieldBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                child: Column(
                  children: [
                    Text(
                      session.clockLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.iconBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.period,
                      style: const TextStyle(
                        color: AppColors.iconBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.fieldBorder,
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.wash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(session.glyphIcon, color: palette.accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.trackLabel.toUpperCase(),
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            CongressCatalog.sessionPinLabel(session),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark session',
                onPressed: onBookmark,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: bookmarked ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({Color wash, Color accent}) _paletteFor(SessionGlyph glyph) {
  return switch (glyph) {
    SessionGlyph.ceremony => (
      wash: AppColors.ceremonyWash,
      accent: AppColors.gold,
    ),
    SessionGlyph.talk => (wash: AppColors.talkWash, accent: AppColors.iconBlue),
    SessionGlyph.nutrition => (
      wash: AppColors.nutritionWash,
      accent: AppColors.nutritionAccent,
    ),
    SessionGlyph.research => (
      wash: AppColors.researchWash,
      accent: AppColors.researchAccent,
    ),
  };
}
