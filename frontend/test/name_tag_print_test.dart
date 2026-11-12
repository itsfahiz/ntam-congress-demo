import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ntam_congress_demo/app/theme/app_theme.dart';
import 'package:ntam_congress_demo/features/auth/data/mock_auth_repository.dart';
import 'package:ntam_congress_demo/features/auth/domain/attendee.dart';
import 'package:ntam_congress_demo/features/auth/state/auth_controller.dart';
import 'package:ntam_congress_demo/features/name_tag/badge_pass_pdf.dart';
import 'package:ntam_congress_demo/features/name_tag/data/badge_qr_repository.dart';
import 'package:ntam_congress_demo/features/name_tag/data/http_badge_qr_repository.dart';
import 'package:ntam_congress_demo/features/name_tag/data/mock_badge_qr_repository.dart';
import 'package:ntam_congress_demo/features/name_tag/name_tag_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _signedUrl =
    'https://ntam-congress-api.onrender.com/badge/verify?b=NMC-2026-001&s=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('badge pass PDF uses signed QR URL and catalog event facts', () async {
    final data = BadgePassData.tryCreate(
      attendee: MockAuthRepository.demoAttendee,
      verifyUrl: _signedUrl,
    );

    expect(data, isNotNull);
    expect(data!.congressName, 'Nestlé Medical Congress');
    expect(data.attendeeName, 'Huda Latheef');
    expect(data.badgeId, 'NMC-2026-001');
    expect(data.verifyUrl, _signedUrl);
    expect(data.dateLabel, 'May 22 - 23, 2026');
    expect(data.location, 'Dubai, UAE');
    expect(HttpBadgeQrRepository.isSignedVerifyUrl(data.verifyUrl), isTrue);
    expect(Uri.parse(data.verifyUrl).queryParameters['b'], data.badgeId);

    final bytes = await buildBadgePassPdf(data);
    expect(bytes.length, greaterThan(100));
    expect(latin1.decode(bytes, allowInvalid: true), startsWith('%PDF'));

    final text = extractPdfText(decodedPdfContent(bytes));
    expect(text, contains('Huda Latheef'));
    expect(text, contains('NMC-2026-001'));
    expect(text, contains('May 22 - 23, 2026'));
    expect(text, contains('Dubai, UAE'));
    expect(text, contains('NESTLÉ MEDICAL CONGRESS'));
    expect(text, contains('Scan to verify attendee'));
    expect(text, isNot(contains('NMC-DEMO-BADGE')));
  });

  test('badge pass PDF is not built from unsigned or demo QR payloads', () {
    expect(
      BadgePassData.tryCreate(
        attendee: MockAuthRepository.demoAttendee,
        verifyUrl: 'NMC-DEMO-BADGE:NMC-2026-001',
      ),
      isNull,
    );
    expect(
      BadgePassData.tryCreate(
        attendee: const Attendee(
          id: '',
          fullName: '',
          email: 'a@b.c',
          role: 'Attendee',
          organization: 'NTAM',
          phone: 'Not provided',
          location: 'Dubai, UAE',
        ),
        verifyUrl: _signedUrl,
      ),
      isNull,
    );
  });

  test('badge pass omits badge ID when it is not an issued NMC id', () {
    const attendee = Attendee(
      id: 'pending',
      fullName: 'Guest Attendee',
      email: 'guest@example.com',
      role: 'Medical Congress Attendee',
      organization: 'NTAM',
      phone: 'Not provided',
      location: 'Dubai, UAE',
    );
    final data = BadgePassData.tryCreate(
      attendee: attendee,
      verifyUrl: _signedUrl,
    );

    expect(data, isNotNull);
    expect(data!.badgeId, isNull);
    expect(data.attendeeName, 'Guest Attendee');
    expect(data.verifyUrl, _signedUrl);
  });

  testWidgets('Print uses the loaded signed QR and catalog pass fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Uint8List? printed;
    final auth = AuthController(MockAuthRepository());
    addTearDown(auth.dispose);
    await _signInDemo(tester, auth);

    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: BadgeQrScope(
          repository: MockBadgeQrRepository(
            badgeIdProvider: () => MockAuthRepository.demoAttendee.id,
          ),
          child: MaterialApp(
            theme: AppTheme.congress(),
            home: NameTagScreen(
              layoutPdf: (bytes) async {
                printed = bytes;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _pumpUntil(
      tester,
      () => find.byType(QrImageView).evaluate().isNotEmpty,
    );
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(QrImageView),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    final verifyUrl = (qr.key as ValueKey<String>).value;
    expect(verifyUrl, MockBadgeQrRepository.urlFor('NMC-2026-001'));
    expect(HttpBadgeQrRepository.isSignedVerifyUrl(verifyUrl), isTrue);

    await tester.tap(find.byTooltip('Print'));
    await _pumpUntil(tester, () => printed != null);

    expect(printed, isNotNull);
    final text = extractPdfText(decodedPdfContent(printed!));
    expect(text, contains('Huda Latheef'));
    expect(text, contains('NMC-2026-001'));
    expect(text, contains('May 22 - 23, 2026'));
    expect(text, contains('Dubai, UAE'));
    expect(text, contains('NESTLÉ MEDICAL CONGRESS'));
    expect(find.text('Printing is not connected'), findsNothing);
  });

  testWidgets('Print does not invent a QR when issuance failed', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var layoutCalls = 0;
    final auth = AuthController(MockAuthRepository());
    addTearDown(auth.dispose);
    await _signInDemo(tester, auth);

    await tester.pumpWidget(
      AuthScope(
        controller: auth,
        child: BadgeQrScope(
          repository: _FailingBadgeQrRepository(),
          child: MaterialApp(
            theme: AppTheme.congress(),
            home: NameTagScreen(
              layoutPdf: (bytes) async {
                layoutCalls += 1;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Print'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(layoutCalls, 0);
    expect(find.text('Could not load your verification badge.'), findsWidgets);
  });
}

class _FailingBadgeQrRepository implements BadgeQrRepository {
  @override
  Future<String> issueVerifyUrl() async {
    throw const BadgeQrException('Could not load your verification badge.');
  }
}

Future<void> _signInDemo(WidgetTester tester, AuthController auth) async {
  final pending = auth.signIn(
    email: MockAuthRepository.demoAttendee.email,
    password: MockAuthRepository.demoPassword,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await pending;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() isDone, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (isDone()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// PDF page content lives in zlib-compressed (FlateDecode) streams.
/// This helper is deliberately test-only and intended for the known PDF
/// format generated by this project, not arbitrary third-party PDFs.
String decodedPdfContent(Uint8List bytes) {
  final out = BytesBuilder();
  const streamMarker = [115, 116, 114, 101, 97, 109]; // stream
  const endMarker = [101, 110, 100, 115, 116, 114, 101, 97, 109]; // endstream
  var cursor = 0;

  while (true) {
    final start = _indexOfBytes(bytes, streamMarker, cursor);
    if (start < 0) break;
    var dataStart = start + streamMarker.length;
    if (dataStart < bytes.length && bytes[dataStart] == 0x0d) dataStart++;
    if (dataStart < bytes.length && bytes[dataStart] == 0x0a) dataStart++;

    final end = _indexOfBytes(bytes, endMarker, dataStart);
    if (end < 0) break;
    var dataEnd = end;
    if (dataEnd > dataStart && bytes[dataEnd - 1] == 0x0a) dataEnd--;
    if (dataEnd > dataStart && bytes[dataEnd - 1] == 0x0d) dataEnd--;

    final slice = bytes.sublist(dataStart, dataEnd);
    try {
      out.add(zlib.decode(slice));
    } catch (_) {
      out.add(slice);
    }
    cursor = end + endMarker.length;
  }

  return latin1.decode(out.takeBytes(), allowInvalid: true);
}

int _indexOfBytes(Uint8List source, List<int> needle, int start) {
  if (needle.isEmpty || start >= source.length) return -1;
  final lastStart = source.length - needle.length;
  for (var i = start; i <= lastStart; i++) {
    var found = true;
    for (var j = 0; j < needle.length; j++) {
      if (source[i + j] != needle[j]) {
        found = false;
        break;
      }
    }
    if (found) return i;
  }
  return -1;
}

/// Reassembles individual PDF text-show operators. dart_pdf often emits
/// each word separately: [(Huda)]TJ ... [(Latheef)]TJ.
String extractPdfText(String decompressedContent) {
  final words = RegExp(
    r'\[\((.*?)\)\]TJ',
    dotAll: true,
  ).allMatches(decompressedContent).map((match) => match.group(1)!).toList();
  return words.join(' ');
}
