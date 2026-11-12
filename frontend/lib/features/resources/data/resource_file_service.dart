import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../congress/domain/congress_models.dart';
import 'demo_resource_pdf.dart';

/// Generates an actual document or loads an original bundled demo video.
/// A bookmark is stored remotely; exported/downloaded bytes are saved locally.
abstract final class ResourceFileService {
  static String filename(CongressResource resource) =>
      resource.kind == ResourceKind.video
          ? 'ntam-day1-demo-recap.mp4'
          : 'ntam-${resource.id}.pdf';

  static Future<Uint8List> bytes(CongressResource resource) async {
    if (resource.kind == ResourceKind.video) {
      final data = await rootBundle.load('assets/media/day1_demo_recap.mp4');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return DemoResourcePdf.build(resource);
  }

  /// Local on-device copy, private to the app and available after app restart.
  static Future<File> saveOffline(CongressResource resource) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/congress_resources');
    if (!await folder.exists()) await folder.create(recursive: true);
    final file = File('${folder.path}/${filename(resource)}');
    await file.writeAsBytes(await bytes(resource), flush: true);
    return file;
  }

  static const _downloadChannel = MethodChannel('ntam.congress/downloads');

  /// Android 10+: write a publicly visible file through MediaStore Downloads.
  /// Older Android / other platforms use Export to Files instead.
  static Future<String> download(CongressResource resource) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const PlatformException(
        code: 'EXPORT_REQUIRED',
        message: 'Use Export to save this file on your device.',
      );
    }
    final result = await _downloadChannel.invokeMethod<String>(
      'saveToDownloads',
      {
        'filename': filename(resource),
        'mimeType': resource.kind == ResourceKind.video
            ? 'video/mp4'
            : 'application/pdf',
        'bytes': await bytes(resource),
      },
    );
    if (result == null || result.isEmpty) {
      throw const PlatformException(
        code: 'DOWNLOAD_FAILED',
        message: 'The download did not return a file location.',
      );
    }
    return result;
  }

  /// Export the real bytes through the platform share/save-to-files sheet.
  static Future<void> export(CongressResource resource) async {
    final file = await saveOffline(resource);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path,
          mimeType: resource.kind == ResourceKind.video
              ? 'video/mp4'
              : 'application/pdf')],
      title: resource.title,
      text: 'NTAM Congress original assessment-demo resource.',
    ));
  }
}
