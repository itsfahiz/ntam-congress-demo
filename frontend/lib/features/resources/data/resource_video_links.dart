/// Registry of publisher-hosted educational videos available in the app.
/// Retaining the original resource ID preserves existing PostgreSQL bookmarks.
abstract final class ResourceVideoLinks {
  static const stanfordVideoId = 'z7x1aaZ03xU';
  static const stanfordTrailerUrl =
      'https://www.youtube.com/watch?v=z7x1aaZ03xU';

  static String? videoIdForResource(String id) =>
      id == 'session-recap' ? stanfordVideoId : null;

  static Uri? forResource(String id) =>
      videoIdForResource(id) == null ? null : Uri.parse(stanfordTrailerUrl);
}
