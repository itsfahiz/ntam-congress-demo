import '../../../app/app_routes.dart';
import '../domain/home_models.dart';

/// Home-only notices. Sessions and shortcuts live in [CongressCatalog].
abstract final class HomeMockData {
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
