import 'package:flutter/material.dart';

enum SessionTrack { keynote, nutrition, research }

enum QuickAccessIcon {
  agenda,
  speakers,
  nameTag,
  venue,
  voting,
  qa,
  resources,
  exhibitors,
}

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

class QuickAccessItem {
  const QuickAccessItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final QuickAccessIcon icon;
  final String route;

  IconData get iconData => switch (icon) {
    QuickAccessIcon.agenda => Icons.calendar_month_outlined,
    QuickAccessIcon.speakers => Icons.groups_outlined,
    QuickAccessIcon.nameTag => Icons.badge_outlined,
    QuickAccessIcon.venue => Icons.location_on_outlined,
    QuickAccessIcon.voting => Icons.bar_chart_rounded,
    QuickAccessIcon.qa => Icons.chat_bubble_outline_rounded,
    QuickAccessIcon.resources => Icons.folder_outlined,
    QuickAccessIcon.exhibitors => Icons.work_outline_rounded,
  };
}

class CongressSession {
  const CongressSession({
    required this.id,
    required this.title,
    required this.speaker,
    required this.location,
    required this.timeLabel,
    required this.track,
  });

  final String id;
  final String title;
  final String speaker;
  final String location;
  final String timeLabel;
  final SessionTrack track;

  String get trackLabel => switch (track) {
    SessionTrack.keynote => 'Keynote',
    SessionTrack.nutrition => 'Nutrition',
    SessionTrack.research => 'Research',
  };
}

class HomeNotification {
  const HomeNotification({
    required this.title,
    required this.body,
    required this.route,
  });

  final String title;
  final String body;
  final String route;
}
