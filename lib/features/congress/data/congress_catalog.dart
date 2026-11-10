import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../domain/congress_models.dart';

/// Local congress content shared by Home, Quick Access and Agenda.
/// Not fetched from a server.
abstract final class CongressCatalog {
  static const featuredEvent = FeaturedEvent(
    title: 'The Next Era of Nutrition & Health',
    dateLabel: 'May 22 - 23, 2026',
    location: 'Dubai, UAE',
  );

  static const days = <CongressDayInfo>[
    CongressDayInfo(
      day: CongressDay.day1,
      shortLabel: 'Day 1',
      dateShort: 'May 22',
      headline: 'Day 1 Schedule',
      dateLong: 'Thursday, May 22, 2026',
    ),
    CongressDayInfo(
      day: CongressDay.day2,
      shortLabel: 'Day 2',
      dateShort: 'May 23',
      headline: 'Day 2 Schedule',
      dateLong: 'Friday, May 23, 2026',
    ),
  ];

  static const quickAccessItems = <QuickAccessItem>[
    QuickAccessItem(
      label: 'Agenda',
      description: 'View full congress schedule',
      category: QuickAccessCategory.event,
      icon: Icons.calendar_month_outlined,
      route: AppRoutes.agenda,
    ),
    QuickAccessItem(
      label: 'Speakers',
      description: 'Explore global medical experts',
      category: QuickAccessCategory.event,
      icon: Icons.groups_outlined,
      route: AppRoutes.speakers,
    ),
    QuickAccessItem(
      label: 'Name Tag',
      description: 'Access your digital badge',
      category: QuickAccessCategory.tools,
      icon: Icons.badge_outlined,
      route: AppRoutes.nameTag,
    ),
    QuickAccessItem(
      label: 'Venue',
      description: 'Location, facilities and directions',
      category: QuickAccessCategory.event,
      icon: Icons.location_on_outlined,
      route: AppRoutes.venue,
    ),
    QuickAccessItem(
      label: 'Voting',
      description: 'Join live audience polls',
      category: QuickAccessCategory.interactive,
      icon: Icons.bar_chart_rounded,
      route: AppRoutes.voting,
    ),
    QuickAccessItem(
      label: 'Ask Q&A',
      description: 'Submit questions to speakers',
      category: QuickAccessCategory.interactive,
      icon: Icons.chat_bubble_outline_rounded,
      route: AppRoutes.qa,
    ),
    QuickAccessItem(
      label: 'Resources',
      description: 'Slides, PDFs and session files',
      category: QuickAccessCategory.tools,
      icon: Icons.folder_outlined,
      route: AppRoutes.resources,
    ),
    QuickAccessItem(
      label: 'Exhibitors',
      description: 'Discover partner booths',
      category: QuickAccessCategory.event,
      icon: Icons.work_outline_rounded,
      route: AppRoutes.exhibitors,
    ),
  ];

  static const sessions = <CongressSession>[
    CongressSession(
      id: 'opening',
      day: CongressDay.day1,
      title: 'Opening Ceremony',
      speaker: 'Congress Committee',
      location: 'Main Auditorium',
      timeLabel: '08:30 AM',
      hour: 8,
      minute: 30,
      track: SessionTrack.keynote,
      glyph: SessionGlyph.ceremony,
      highlighted: true,
      summary:
          'Welcome remarks and congress overview for The Next Era of Nutrition & Health.',
    ),
    CongressSession(
      id: 'welcome',
      day: CongressDay.day1,
      title: 'Welcome & Introduction',
      speaker: 'Dr. Hassan Ali',
      location: 'Main Auditorium',
      timeLabel: '09:30 AM',
      hour: 9,
      minute: 30,
      track: SessionTrack.keynote,
      glyph: SessionGlyph.talk,
      summary:
          'Clinical Research Director Dr. Hassan Ali frames the scientific programme.',
    ),
    CongressSession(
      id: 'pediatric',
      day: CongressDay.day1,
      title: 'Future of Pediatric Nutrition',
      speaker: 'Dr. Sarah Johnson',
      location: 'Hall B',
      timeLabel: '10:30 AM',
      hour: 10,
      minute: 30,
      track: SessionTrack.nutrition,
      glyph: SessionGlyph.nutrition,
      summary:
          'Pediatric nutrition specialist Dr. Sarah Johnson on personalised feeding plans.',
    ),
    CongressSession(
      id: 'research',
      day: CongressDay.day1,
      title: 'Clinical Research Highlights',
      speaker: 'Dr. Ahmed Khalid',
      location: 'Hall C',
      timeLabel: '11:30 AM',
      hour: 11,
      minute: 30,
      track: SessionTrack.research,
      glyph: SessionGlyph.research,
      summary:
          'A review of recent clinical findings presented by Dr. Ahmed Khalid.',
    ),
    CongressSession(
      id: 'policy',
      day: CongressDay.day2,
      title: 'Nutrition Policy Roundtable',
      speaker: 'Dr. Sarah Johnson',
      location: 'Hall A',
      timeLabel: '09:00 AM',
      hour: 9,
      minute: 0,
      track: SessionTrack.nutrition,
      glyph: SessionGlyph.nutrition,
      summary:
          'Policy and practice discussion on public-health nutrition in the region.',
    ),
    CongressSession(
      id: 'translational',
      day: CongressDay.day2,
      title: 'Translational Research Insights',
      speaker: 'Dr. Ahmed Khalid',
      location: 'Hall C',
      timeLabel: '10:30 AM',
      hour: 10,
      minute: 30,
      track: SessionTrack.research,
      glyph: SessionGlyph.research,
      summary: 'How recent studies translate into bedside nutrition protocols.',
    ),
    CongressSession(
      id: 'workshop',
      day: CongressDay.day2,
      title: 'Personalized Nutrition Workshop',
      speaker: 'Dr. Hassan Ali',
      location: 'Hall B',
      timeLabel: '12:00 PM',
      hour: 12,
      minute: 0,
      track: SessionTrack.nutrition,
      glyph: SessionGlyph.talk,
      summary:
          'Interactive workshop on building attendee-ready nutrition plans.',
    ),
    CongressSession(
      id: 'closing',
      day: CongressDay.day2,
      title: 'Closing Keynote',
      speaker: 'Congress Committee',
      location: 'Main Auditorium',
      timeLabel: '02:00 PM',
      hour: 14,
      minute: 0,
      track: SessionTrack.keynote,
      glyph: SessionGlyph.ceremony,
      highlighted: true,
      summary: 'Key takeaways and close of The Next Era of Nutrition & Health.',
    ),
  ];

  static CongressDayInfo infoFor(CongressDay day) {
    return days.firstWhere((info) => info.day == day);
  }

  static List<CongressSession> sessionsOn(CongressDay day) {
    return sessions.where((session) => session.day == day).toList();
  }

  static List<CongressSession> upcomingForHome() {
    return sessionsOn(CongressDay.day1);
  }

  static List<CongressSession> filterSessions({
    required CongressDay day,
    SessionTrack? track,
    String query = '',
  }) {
    final needle = query.trim().toLowerCase();
    return sessions.where((session) {
      if (session.day != day) return false;
      if (track != null && session.track != track) return false;
      if (needle.isEmpty) return true;
      final haystack =
          '${session.title} ${session.speaker} ${session.location} ${session.trackLabel}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  static List<QuickAccessItem> filterQuickAccess({
    QuickAccessCategory? category,
    String query = '',
  }) {
    final needle = query.trim().toLowerCase();
    return quickAccessItems.where((item) {
      if (category != null && item.category != category) return false;
      if (needle.isEmpty) return true;
      final haystack = '${item.label} ${item.description} ${item.categoryLabel}'
          .toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }
}
