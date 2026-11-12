import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../congress/domain/congress_models.dart';
import 'demo_resource_pdf.dart';

/// PDF export. Third-party YouTube media is never downloaded here.
abstract final class ResourceFileService {
  static String filename(CongressResource resource) {
    if (resource.kind == ResourceKind.video) {
      throw UnsupportedError('External videos are not downloadable.');
    }
    return 'ntam-${resource.id}.pdf';
  }

  static Future<Uint8List> bytes(CongressResource resource) {
    if (resource.kind == ResourceKind.video) {
      throw UnsupportedError('External videos are not downloadable.');
    }
    return DemoResourcePdf.build(resource);
  }

  static Future<File> saveOffline(CongressResource resource) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/congress_resources');
    if (!await folder.exists()) await folder.create(recursive: true);
    final file = File('${folder.path}/${filename(resource)}');
    await file.writeAsBytes(await bytes(resource), flush: true);
    return file;
  }

  /// The user selects the final destination from the platform share/save sheet.
  static Future<void> export(CongressResource resource) async {
    final file = await saveOffline(resource);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      title: resource.title,
      text: 'NTAM Congress original assessment-demo document.',
    ));
  }
}
