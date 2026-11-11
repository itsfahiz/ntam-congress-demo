import 'package:flutter_test/flutter_test.dart';
import 'package:ntam_congress_demo/features/name_tag/data/badge_qr_repository.dart';
import 'package:ntam_congress_demo/features/name_tag/data/http_badge_qr_repository.dart';
import 'package:ntam_congress_demo/features/name_tag/data/mock_badge_qr_repository.dart';

void main() {
  const signedUrl =
      'https://ntam-congress-api.onrender.com/badge/verify?b=NMC-1BAC3BF0&s=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  test('HttpBadgeQrRepository parses a signed verification URL', () async {
    final repository = HttpBadgeQrRepository(
      tokenProvider: () => 'test-token',
      baseUrl: 'https://ntam-congress-api.onrender.com',
      get:
          ({
            required uri,
            required headers,
            required timeout,
          }) async {
            expect(uri.path, '/api/me/badge');
            expect(headers['Authorization'], 'Bearer test-token');
            return BadgeQrHttpResponse(
              statusCode: 200,
              body:
                  '{"badgeId":"NMC-1BAC3BF0","verifyUrl":"$signedUrl"}',
            );
          },
    );

    expect(await repository.issueVerifyUrl(), signedUrl);
  });

  test('HttpBadgeQrRepository rejects a demo or unsigned payload', () async {
    final repository = HttpBadgeQrRepository(
      tokenProvider: () => 'test-token',
      get:
          ({
            required uri,
            required headers,
            required timeout,
          }) async {
            return const BadgeQrHttpResponse(
              statusCode: 200,
              body: '{"badgeId":"NMC-1BAC3BF0","verifyUrl":"NMC-DEMO-BADGE:NMC-1BAC3BF0"}',
            );
          },
    );

    expect(
      () => repository.issueVerifyUrl(),
      throwsA(isA<BadgeQrException>()),
    );
  });

  test('HttpBadgeQrRepository requires a signed-in token', () async {
    final repository = HttpBadgeQrRepository(tokenProvider: () => '');
    expect(
      () => repository.issueVerifyUrl(),
      throwsA(
        isA<BadgeQrException>().having(
          (error) => error.message,
          'message',
          'Sign in to load your verification badge.',
        ),
      ),
    );
  });

  test('isSignedVerifyUrl accepts only HTTPS-or-HTTP verify links', () {
    expect(HttpBadgeQrRepository.isSignedVerifyUrl(signedUrl), isTrue);
    expect(
      HttpBadgeQrRepository.isSignedVerifyUrl(
        MockBadgeQrRepository.urlFor('NMC-2026-001'),
      ),
      isTrue,
    );
    expect(
      HttpBadgeQrRepository.isSignedVerifyUrl('NMC-DEMO-BADGE:NMC-2026-001'),
      isFalse,
    );
    expect(
      HttpBadgeQrRepository.isSignedVerifyUrl(
        'https://ntam-congress-api.onrender.com/badge/verify?b=NMC-1BAC3BF0',
      ),
      isFalse,
    );
  });
}
