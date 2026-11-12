import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

typedef BadgePdfLayout =
    Future<bool> Function(Uint8List bytes);

Future<bool> layoutBadgePassPdf(Uint8List bytes) {
  return Printing.layoutPdf(
    name: 'NTAM Congress Badge',
    format: PdfPageFormat.a6,
    dynamicLayout: false,
    onLayout: (_) async => bytes,
  );
}
