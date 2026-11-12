import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../congress/data/congress_catalog.dart';
import '../../congress/domain/congress_models.dart';

/// Original assessment-demo PDFs generated from the local congress catalogue.
/// They are not official Nestle publications or medical guidance.
class DemoResourcePdf {
  static String _plain(String source) => source
      .replaceAll('•', '-')
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('·', '|')
      .replaceAll('’', "'")
      .replaceAll('é', 'e');

  static pw.Widget _heading(String title, {double size = 21}) => pw.Text(
        _plain(title),
        style: pw.TextStyle(
          color: PdfColor.fromHex('#0B356B'),
          fontSize: size,
          fontWeight: pw.FontWeight.bold,
        ),
      );

  static pw.Widget _disclaimer() => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        color: PdfColor.fromHex('#EEF5FF'),
        child: pw.Text(
          'NTAM assessment demo only. Illustrative event material, not an '
          'official Nestle document, confirmed congress record, or medical advice.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      );

  static Future<Uint8List> build(CongressResource resource) async {
    if (resource.kind == ResourceKind.video) {
      throw ArgumentError('External videos cannot be converted to a PDF.');
    }
    final doc = pw.Document(
      title: _plain(resource.title),
      author: 'NTAM assessment demo',
    );

    if (resource.id == 'keynote-slides') {
      final slides = <(String, String)>[
        (
          'The Next Era of Nutrition & Health',
          'Nestle Medical Congress | Dubai, UAE | 22-23 May 2026'
        ),
        (
          'Opening Ceremony',
          '08:30 AM | Main Auditorium\nCongress Committee'
        ),
        (
          'Welcome & Introduction',
          '09:30 AM | Main Auditorium\nDr. Hassan Ali'
        ),
        (
          'Future of Pediatric Nutrition',
          '10:30 AM | Hall B\nDr. Sarah Johnson'
        ),
        (
          'Closing Takeaways',
          'See the full congress programme for the remaining Day 1 '
              'and Day 2 sessions.\nDemonstration slides only.'
        ),
      ];
      for (var index = 0; index < slides.length; index++) {
        final slide = slides[index];
        doc.addPage(pw.Page(
          pageFormat: const PdfPageFormat(960, 540),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Container(
            padding: const pw.EdgeInsets.all(52),
            color: PdfColor.fromHex('#052453'),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('NESTLE MEDICAL CONGRESS | DEMO SLIDES',
                    style: pw.TextStyle(
                      fontSize: 15, color: PdfColor.fromHex('#74D8F8'))),
                pw.Spacer(),
                pw.Text(_plain(slide.$1),
                    style: pw.TextStyle(
                      fontSize: 40,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text(_plain(slide.$2),
                    style: const pw.TextStyle(
                      fontSize: 21, color: PdfColors.white)),
                pw.Spacer(),
                pw.Divider(color: PdfColor.fromHex('#00BDEE')),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Original illustrative assessment content',
                        style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.white)),
                    pw.Text('${index + 1} / ${slides.length}',
                        style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.white)),
                  ]),
              ],
            ),
          ),
        ));
      }
      return doc.save();
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(38),
      build: (_) => [
        _heading(resource.title),
        pw.SizedBox(height: 6),
        pw.Text('The Next Era of Nutrition & Health',
            style: const pw.TextStyle(fontSize: 13)),
        pw.SizedBox(height: 4),
        pw.Text('Dubai, UAE | 22-23 May 2026',
            style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 18),
        _disclaimer(),
        pw.SizedBox(height: 24),
        if (resource.id == 'programme') ...[
          for (final day in CongressCatalog.days) ...[
            _heading(day.dateLong, size: 16),
            pw.SizedBox(height: 10),
            for (final session in CongressCatalog.sessionsOn(day.day))
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 13),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${session.timeLabel} | ${_plain(session.title)}',
                        style: pw.TextStyle(fontSize: 12,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${_plain(CongressCatalog.speakerName(session))} | '
                      '${_plain(session.location)} | ${session.trackLabel}',
                      style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_plain(session.summary),
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            pw.SizedBox(height: 10),
          ],
        ] else ...[
          _heading('Pediatric Nutrition: Discussion Guide', size: 16),
          pw.SizedBox(height: 12),
          pw.Text(
            'Session: Future of Pediatric Nutrition\n'
            'Speaker: Dr. Sarah Johnson\n'
            'Day 1 | 10:30 AM | Hall B',
            style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 18),
          _heading('Attendee discussion prompts', size: 14),
          pw.SizedBox(height: 10),
          for (final question in [
            'What research questions are being explored in pediatric nutrition?',
            'How should evidence be reviewed before applying a new approach?',
            'What implementation challenges could be discussed with the faculty?',
            'Which outcomes could be evaluated in future research?',
            'What follow-up questions would be appropriate for the Q&A?',
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text('- $question',
                  style: const pw.TextStyle(fontSize: 12))),
          pw.SizedBox(height: 18),
          pw.Text(
            'This demo guide is an attendee question prompt sheet. '
            'It is not clinical advice, a treatment protocol, or an '
            'evidence-based reference.',
            style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    ));
    return doc.save();
  }
}
