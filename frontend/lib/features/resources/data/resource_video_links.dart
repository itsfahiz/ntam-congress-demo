import 'package:url_launcher/url_launcher.dart';

/// Public Stanford educational trailer, not congress recording.
abstract final class ResourceVideoLinks {
  static const stanfordTrailerUrl =
      'https://www.youtube.com/watch?v=z7x1aaZ03xU';

  // Keep old key so PostgreSQL bookmarks survive the resource update.
  static Uri? forResource(String id) =>
      id == 'session-recap' ? Uri.parse(stanfordTrailerUrl) : null;

  static Future<bool> watch(String id) async {
    final uri = forResource(id);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
