import '../../../app/app_routes.dart';
import '../domain/home_models.dart';

/// Home-only notices. Sessions and shortcuts live in [CongressCatalog].
abstract final class HomeMockData {
  static const notifications = <HomeNotification>[
    HomeNotification(
      title: 'Opening Ceremony — programme information',
      body: 'Day 1 · Main Auditorium · 08:30 AM',
      route: AppRoutes.agenda,
    ),
    HomeNotification(
      title: 'Congress Q&A',
      body: 'View and submit questions in the congress discussion.',
      route: AppRoutes.qa,
    ),
    HomeNotification(
      title: 'Programme resource available',
      body: 'Congress Scientific Programme is now in the library.',
      route: AppRoutes.resources,
    ),
  ];
}
