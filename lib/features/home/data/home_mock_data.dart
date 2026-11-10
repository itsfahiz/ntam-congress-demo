import '../../../app/app_routes.dart';
import '../domain/home_models.dart';

abstract final class HomeMockData {
  static const featuredEvent = FeaturedEvent(
    title: 'The Next Era of Nutrition & Health',
    dateLabel: 'May 22 - 23, 2026',
    location: 'Dubai, UAE',
  );

  static const quickAccessItems = <QuickAccessItem>[
    QuickAccessItem(
      label: 'Agenda',
      icon: QuickAccessIcon.agenda,
      route: AppRoutes.agenda,
    ),
    QuickAccessItem(
      label: 'Speakers',
      icon: QuickAccessIcon.speakers,
      route: AppRoutes.speakers,
    ),
    QuickAccessItem(
      label: 'Name Tag',
      icon: QuickAccessIcon.nameTag,
      route: AppRoutes.nameTag,
    ),
    QuickAccessItem(
      label: 'Venue',
      icon: QuickAccessIcon.venue,
      route: AppRoutes.venue,
    ),
    QuickAccessItem(
      label: 'Voting',
      icon: QuickAccessIcon.voting,
      route: AppRoutes.voting,
    ),
    QuickAccessItem(
      label: 'Ask Q&A',
      icon: QuickAccessIcon.qa,
      route: AppRoutes.qa,
    ),
    QuickAccessItem(
      label: 'Resources',
      icon: QuickAccessIcon.resources,
      route: AppRoutes.resources,
    ),
    QuickAccessItem(
      label: 'Exhibitors',
      icon: QuickAccessIcon.exhibitors,
      route: AppRoutes.exhibitors,
    ),
  ];

  static const sessions = <CongressSession>[
    CongressSession(
      id: 'opening',
      title: 'Opening Ceremony',
      speaker: 'Congress Committee',
      location: 'Main Auditorium',
      timeLabel: '08:30 AM',
      track: SessionTrack.keynote,
    ),
    CongressSession(
      id: 'welcome',
      title: 'Welcome & Introduction',
      speaker: 'Dr. Hassan Ali',
      location: 'Main Auditorium',
      timeLabel: '09:30 AM',
      track: SessionTrack.keynote,
    ),
    CongressSession(
      id: 'pediatric',
      title: 'Future of Pediatric Nutrition',
      speaker: 'Dr. Sarah Johnson',
      location: 'Hall B',
      timeLabel: '10:30 AM',
      track: SessionTrack.nutrition,
    ),
    CongressSession(
      id: 'research',
      title: 'Clinical Research Highlights',
      speaker: 'Dr. Ahmed Khalid',
      location: 'Hall C',
      timeLabel: '11:30 AM',
      track: SessionTrack.research,
    ),
  ];

  static const notifications = <HomeNotification>[
    HomeNotification(
      title: 'Opening Ceremony starts soon',
      body: 'Main Auditorium · 08:30 AM',
      route: AppRoutes.agenda,
    ),
    HomeNotification(
      title: 'Live Q&A is open',
      body: 'Submit a question for the morning keynote.',
      route: AppRoutes.qa,
    ),
    HomeNotification(
      title: 'New resource added',
      body: 'Congress Scientific Programme is now in the library.',
      route: AppRoutes.resources,
    ),
  ];
}
