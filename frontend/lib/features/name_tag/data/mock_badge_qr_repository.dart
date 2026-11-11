import 'badge_qr_repository.dart';

/// Widget-test stand-in. Production uses [HttpBadgeQrRepository].
class MockBadgeQrRepository implements BadgeQrRepository {
  MockBadgeQrRepository({this.badgeIdProvider});

  final String Function()? badgeIdProvider;

  static const verifyOrigin = 'https://ntam-congress-api.onrender.com';
  static const testSignature =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  static String urlFor(String badgeId) {
    return Uri.parse(verifyOrigin)
        .replace(
          path: '/badge/verify',
          queryParameters: {'b': badgeId, 's': testSignature},
        )
        .toString();
  }

  @override
  Future<String> issueVerifyUrl() async {
    final badgeId = badgeIdProvider?.call() ?? '';
    if (badgeId.isEmpty) {
      throw const BadgeQrException('Sign in to load your verification badge.');
    }
    return urlFor(badgeId);
  }
}
