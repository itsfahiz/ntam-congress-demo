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
      dateLong: 'Friday, May 22, 2026',
    ),
    CongressDayInfo(
      day: CongressDay.day2,
      shortLabel: 'Day 2',
      dateShort: 'May 23',
      headline: 'Day 2 Schedule',
      dateLong: 'Saturday, May 23, 2026',
    ),
  ];

  static const committeeId = 'committee';
  static const sarahId = 'sarah';
  static const hassanId = 'hassan';
  static const ahmedId = 'ahmed';

  /// Faculty copy from the PDF, plus one illustrative listing for Ahmed.
  /// Bios are demo text, not real CVs.
  static const speakers = <CongressSpeaker>[
    CongressSpeaker(
      id: sarahId,
      fullName: 'Dr. Sarah Johnson',
      title: 'Pediatric Nutrition Specialist',
      country: 'United Kingdom',
      focuses: [SpeakerFocus.nutrition, SpeakerFocus.pediatrics],
      featured: true,
      bio:
          'Demo faculty profile for the assessment app. Titles follow the PDF; this is not a real biography.',
    ),
    CongressSpeaker(
      id: hassanId,
      fullName: 'Dr. Hassan Ali',
      title: 'Clinical Research Director',
      country: 'UAE',
      focuses: [SpeakerFocus.research, SpeakerFocus.nutrition],
      bio:
          'Demo faculty profile for the assessment app. Titles follow the PDF; this is not a real biography.',
    ),
    CongressSpeaker(
      id: ahmedId,
      fullName: 'Dr. Ahmed Khalid',
      title: 'Research faculty (demo)',
      country: 'Unspecified (demo)',
      focuses: [SpeakerFocus.research],
      bio:
          'The PDF cuts off this card. Country and title are illustrative demo fields, not a real affiliation.',
    ),
    CongressSpeaker(
      id: committeeId,
      fullName: 'Congress Committee',
      title: 'Programme hosts',
      country: 'Dubai, UAE',
      focuses: [],
      listed: false,
      bio:
          'Host listing for committee-led sessions. Not a personal speaker page.',
    ),
  ];

  /// Venue copy from the assessment PDF. Map pin is official DWTC, not a booking.
  static const venue = CongressVenue(
    name: 'Dubai International Convention & Exhibition Center',
    dateLabel: '22 - 23 May 2026',
    address: 'World Trade Centre, Dubai, United Arab Emirates',
    addressDisclaimer:
        'Address text is copied from the assessment reference. The map pin is the official Dubai World Trade Centre location, not a confirmed congress booking.',
    latitude: 25.2230544,
    longitude: 55.2885219,
    directionsUrl:
        'https://www.google.com/maps/search/?api=1&query=25.2230544%2C55.2885219',
    mapMarkerLabel: 'Dubai World Trade Centre',
    facilities: [
      VenueFacility(icon: Icons.wifi_rounded, label: 'Free Wi-Fi'),
      VenueFacility(icon: Icons.local_parking_rounded, label: 'Parking'),
      VenueFacility(icon: Icons.restaurant_rounded, label: 'Catering'),
      VenueFacility(
        icon: Icons.accessible_forward_rounded,
        label: 'Accessible',
      ),
    ],
  );

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
      speakerId: committeeId,
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
      speakerId: hassanId,
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
      speakerId: sarahId,
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
      speakerId: ahmedId,
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
      speakerId: sarahId,
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
      speakerId: ahmedId,
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
      speakerId: hassanId,
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
      speakerId: committeeId,
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

  /// Local demo polls. Counts are simulated samples, not live attendee votes.
  static const polls = <CongressPoll>[
    CongressPoll(
      id: 'session-rating',
      topicLabel: 'Audience Feedback',
      question: 'How would you rate the current session?',
      options: [
        PollOption(id: 'excellent', label: 'Excellent', simulatedVotes: 55),
        PollOption(id: 'very-good', label: 'Very Good', simulatedVotes: 31),
        PollOption(id: 'good', label: 'Good', simulatedVotes: 10),
        PollOption(id: 'fair', label: 'Fair', simulatedVotes: 5),
      ],
    ),
    CongressPoll(
      id: 'workshop-topic',
      topicLabel: 'Programme Planning',
      question: 'Which topic should the next workshop expand?',
      options: [
        PollOption(
          id: 'pediatric',
          label: 'Pediatric nutrition',
          simulatedVotes: 40,
        ),
        PollOption(
          id: 'research-methods',
          label: 'Clinical research methods',
          simulatedVotes: 35,
        ),
        PollOption(
          id: 'policy',
          label: 'Public health policy',
          simulatedVotes: 25,
        ),
      ],
    ),
    CongressPoll(
      id: 'takeaways',
      topicLabel: 'Clinical Practice',
      question: "How useful were today's clinical takeaways?",
      options: [
        PollOption(id: 'apply', label: 'Ready to apply', simulatedVotes: 48),
        PollOption(
          id: 'examples',
          label: 'Need more examples',
          simulatedVotes: 32,
        ),
        PollOption(
          id: 'recap',
          label: 'Prefer a recap session',
          simulatedVotes: 20,
        ),
      ],
    ),
  ];

  /// Seeded Q&A cards. Separate from questions typed on this device.
  static const questions = <CongressQuestion>[
    CongressQuestion(
      id: 'q-growth',
      body:
          'How can pediatric nutrition plans be personalized for children with different growth patterns?',
      topic: QuestionTopic.nutrition,
      authorName: 'Dr. Ahmed Khalid',
      speakerId: ahmedId,
      seedLikes: 24,
      answered: true,
    ),
    CongressQuestion(
      id: 'q-policy',
      body:
          'What regional policy changes would most improve hospital nutrition protocols?',
      topic: QuestionTopic.clinical,
      authorName: 'Dr. Sarah Johnson',
      speakerId: sarahId,
      seedLikes: 11,
      answered: true,
    ),
    CongressQuestion(
      id: 'q-trial',
      body:
          'Which endpoints matter most when translating nutrition trials into bedside practice?',
      topic: QuestionTopic.research,
      authorName: 'Dr. Hassan Ali',
      speakerId: hassanId,
      seedLikes: 18,
    ),
    CongressQuestion(
      id: 'q-general',
      body: 'Will the closing keynote include a recap of both congress days?',
      topic: QuestionTopic.general,
      authorName: 'Congress Committee',
      speakerId: committeeId,
      seedLikes: 6,
    ),
  ];

  /// Illustrative booths for the Exhibitors shortcut. Not an official directory.
  static const exhibitors = <CongressExhibitor>[
    CongressExhibitor(
      id: 'nutrition-pavilion',
      name: 'Nutrition Science Pavilion',
      hall: 'Hall B',
      focus: 'Pediatric nutrition',
      summary: 'Illustrative booth tied to the pediatric nutrition sessions.',
    ),
    CongressExhibitor(
      id: 'research-lounge',
      name: 'Clinical Research Lounge',
      hall: 'Hall C',
      focus: 'Research highlights',
      summary: 'Space for discussing translational research talks.',
    ),
    CongressExhibitor(
      id: 'programme-desk',
      name: 'Programme Host Desk',
      hall: 'Main Auditorium',
      focus: 'Congress information',
      summary: 'Congress information desk for programme and venue questions.',
    ),
  ];

  static List<CongressResource> get resources {
    return [
      CongressResource(
        id: 'programme',
        title: 'Congress Scientific Programme',
        subtitle: 'Complete schedule and session details',
        kind: ResourceKind.pdf,
        body: scientificProgrammeSummary(),
      ),
      CongressResource(
        id: 'pediatric-guide',
        title: 'Pediatric Nutrition Guide',
        subtitle: 'Illustrative discussion prompts (demo PDF)',
        kind: ResourceKind.pdf,
        body:
            'Tied to Future of Pediatric Nutrition with ${speakerById(sarahId).fullName}.\n\n'
            'Talking points:\n'
            '• Personalised feeding plans for different growth patterns\n'
            '• How session takeaways map to hospital nutrition protocols\n'
            '• Questions attendees can raise in Ask Q&A',
      ),
      CongressResource(
        id: 'keynote-slides',
        title: 'Keynote Presentation Slides',
        subtitle: featuredEvent.title,
        kind: ResourceKind.slides,
        body:
            '${featuredEvent.title}\n'
            '${featuredEvent.dateLabel} · ${featuredEvent.location}\n\n'
            '1. Opening Ceremony — Congress Committee, Main Auditorium\n'
            '2. Welcome & Introduction — ${speakerById(hassanId).fullName}\n'
            '3. Future of Pediatric Nutrition — ${speakerById(sarahId).fullName}\n'
            '4. Closing Keynote — programme recap',
      ),
      CongressResource(
        // Preserve stable ID so saved PostgreSQL bookmarks continue working.
        id: 'session-recap',
        title: 'Introduction to Food & Health',
        subtitle: 'Stanford University · Course trailer (YouTube)',
        kind: ResourceKind.video,
        body:
            'Stanford Introduction to Food & Health introduces practical '
            'nutrition and food choices. This is the publicly linked '
            'Stanford course trailer, not a recorded NTAM/Nestle event.\n\n'
            'Source: Stanford University / Digital Medic. '
            'Play Video starts the official YouTube iframe inside this app. '
            'Internet access is required.',
      ),
    ];
  }

  static String scientificProgrammeSummary() {
    final buffer = StringBuffer()
      ..writeln(featuredEvent.title)
      ..writeln('${featuredEvent.dateLabel} · ${featuredEvent.location}')
      ..writeln();
    for (final day in days) {
      buffer.writeln(day.dateLong);
      for (final session in sessionsOn(day.day)) {
        buffer.writeln(
          '${session.timeLabel} · ${session.title} · ${speakerName(session)} · ${session.location}',
        );
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

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
          '${session.title} ${speakerById(session.speakerId).fullName} ${session.location} ${session.trackLabel}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  static CongressSpeaker speakerById(String id) {
    return speakers.firstWhere((speaker) => speaker.id == id);
  }

  static List<CongressSpeaker> get listedSpeakers {
    return speakers.where((speaker) => speaker.listed).toList();
  }

  static List<CongressSession> sessionsForSpeaker(String speakerId) {
    return sessions.where((session) => session.speakerId == speakerId).toList();
  }

  static String speakerName(CongressSession session) {
    return speakerById(session.speakerId).fullName;
  }

  static String sessionPinLabel(CongressSession session) {
    final speaker = speakerById(session.speakerId);
    return speaker.listed ? speaker.fullName : session.location;
  }

  static CongressSession? headlineSessionFor(CongressSpeaker speaker) {
    final owned = sessionsForSpeaker(speaker.id);
    if (owned.isEmpty) return null;
    for (final session in owned) {
      if (session.day == CongressDay.day1) return session;
    }
    return owned.first;
  }

  static List<CongressSpeaker> filterSpeakers({
    SpeakerFocus? focus,
    String query = '',
    Set<String> favoriteIds = const {},
    bool favoritesOnly = false,
  }) {
    final needle = query.trim().toLowerCase();
    return listedSpeakers.where((speaker) {
      if (favoritesOnly && !favoriteIds.contains(speaker.id)) return false;
      if (focus != null && !speaker.focuses.contains(focus)) return false;
      if (needle.isEmpty) return true;
      final sessionTitles = sessionsForSpeaker(
        speaker.id,
      ).map((session) => session.title).join(' ');
      final haystack =
          '${speaker.fullName} ${speaker.title} ${speaker.country} ${speaker.focusLabel} $sessionTitles'
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

  static List<CongressResource> filterResources({
    ResourceKind? kind,
    String query = '',
    Set<String> savedIds = const {},
    bool savedOnly = false,
  }) {
    final needle = query.trim().toLowerCase();
    return resources.where((resource) {
      if (savedOnly && !savedIds.contains(resource.id)) return false;
      if (kind != null && resource.kind != kind) return false;
      if (needle.isEmpty) return true;
      final haystack =
          '${resource.title} ${resource.subtitle} ${resource.kindLabel}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }
}
