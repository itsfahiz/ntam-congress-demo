import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in an installed maps app or browser.
/// Returns false when nothing can handle the URL.
Future<bool> launchVenueDirections(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
