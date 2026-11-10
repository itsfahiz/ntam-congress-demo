import 'package:flutter/material.dart';

enum SessionTrack { keynote, nutrition, research }

enum CongressDay { day1, day2 }

enum QuickAccessCategory { event, interactive, tools }

enum SessionGlyph { ceremony, talk, nutrition, research }

class FeaturedEvent {
  const FeaturedEvent({
    required this.title,
    required this.dateLabel,
    required this.location,
  });

  final String title;
  final String dateLabel;
  final String location;
}

class CongressDayInfo {
  const CongressDayInfo({
    required this.day,
    required this.shortLabel,
    required this.dateShort,
    required this.headline,
    required this.dateLong,
  });

  final CongressDay day;
  final String shortLabel;
  final String dateShort;
  final String headline;
  final String dateLong;
}

class QuickAccessItem {
  const QuickAccessItem({
    required this.label,
    required this.description,
    required this.category,
    required this.icon,
    required this.route,
  });

  final String label;
  final String description;
  final QuickAccessCategory category;
  final IconData icon;
  final String route;

  String get categoryLabel => switch (category) {
    QuickAccessCategory.event => 'Event',
    QuickAccessCategory.interactive => 'Interactive',
    QuickAccessCategory.tools => 'Tools',
  };
}

class CongressSession {
  const CongressSession({
    required this.id,
    required this.day,
    required this.title,
    required this.speaker,
    required this.location,
    required this.timeLabel,
    required this.hour,
    required this.minute,
    required this.track,
    required this.glyph,
    required this.summary,
    this.highlighted = false,
  });

  final String id;
  final CongressDay day;
  final String title;
  final String speaker;
  final String location;
  final String timeLabel;
  final int hour;
  final int minute;
  final SessionTrack track;
  final SessionGlyph glyph;
  final String summary;
  final bool highlighted;

  String get trackLabel => switch (track) {
    SessionTrack.keynote => 'Keynote',
    SessionTrack.nutrition => 'Nutrition',
    SessionTrack.research => 'Research',
  };

  String get period => hour >= 12 ? 'PM' : 'AM';

  String get clockLabel {
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Reference cards pin a named speaker; committee sessions pin the hall.
  String get pinLabel => speaker.startsWith('Dr.') ? speaker : location;

  IconData get glyphIcon => switch (glyph) {
    SessionGlyph.ceremony => Icons.calendar_month_rounded,
    SessionGlyph.talk => Icons.mic_none_rounded,
    SessionGlyph.nutrition => Icons.eco_rounded,
    SessionGlyph.research => Icons.biotech_outlined,
  };
}
