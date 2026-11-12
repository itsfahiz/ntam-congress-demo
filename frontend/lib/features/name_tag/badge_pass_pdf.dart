import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../auth/domain/attendee.dart';
import '../congress/data/congress_catalog.dart';
import 'data/http_badge_qr_repository.dart';

const _navy = PdfColor(0x04 / 255, 0x12 / 255, 0x2F / 255);
const _gold = PdfColor(0xF0 / 255, 0xC1 / 255, 0x4B / 255);
const _ink = PdfColor(0x14 / 255, 0x21 / 255, 0x3D / 255);
const _muted = PdfColor(0x5C / 255, 0x65 / 255, 0x78 / 255);
const _badgeIdPattern = r'^NMC-[A-Z0-9-]{1,32}$';

class BadgePassData {
  const BadgePassData({
    required this.congressName,
    required this.attendeeName,
    required this.verifyUrl,
    required this.dateLabel,
    required this.location,
    this.badgeId,
  });

  final String congressName;
  final String attendeeName;
  final String? badgeId;
  final String verifyUrl;
  final String dateLabel;
  final String location;

  static BadgePassData? tryCreate({
    required Attendee attendee,
    required String verifyUrl,
  }) {
    if (!HttpBadgeQrRepository.isSignedVerifyUrl(verifyUrl)) return null;
    final name = attendee.fullName.trim();
    if (name.isEmpty) return null;
    final rawId = attendee.id.trim();
    final badgeId = RegExp(_badgeIdPattern).hasMatch(rawId) ? rawId : null;
    final event = CongressCatalog.featuredEvent;
    return BadgePassData(
      congressName: 'Nestlé Medical Congress',
      attendeeName: name,
      badgeId: badgeId,
      verifyUrl: verifyUrl,
      dateLabel: event.dateLabel,
      location: event.location,
    );
  }
}

Future<Uint8List> buildBadgePassPdf(BadgePassData data) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a6,
      margin: const pw.EdgeInsets.all(14),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    data.congressName.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Container(width: 36, height: 1.4, color: _gold),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              data.attendeeName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (data.badgeId != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Badge ID  ${data.badgeId}',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
            pw.SizedBox(height: 10),
            pw.Expanded(
              child: pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _navy, width: 1.2),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: data.verifyUrl,
                    color: _navy,
                    width: 92,
                    height: 92,
                    drawText: false,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Scan to verify attendee',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              data.dateLabel,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: _ink,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              data.location,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(color: _muted, fontSize: 9),
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}
