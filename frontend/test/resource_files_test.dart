import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/features/congress/data/congress_catalog.dart';
import 'package:ntam_congress_demo/features/congress/domain/congress_models.dart';
import 'package:ntam_congress_demo/features/resources/data/demo_resource_pdf.dart';
import 'package:ntam_congress_demo/features/resources/data/resource_file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all document resources generate real PDF bytes', () async {
    final documents = CongressCatalog.resources.where(
      (resource) => resource.kind != ResourceKind.video);
    expect(documents.length, 3);
    for (final resource in documents) {
      final bytes = await DemoResourcePdf.build(resource);
      expect(bytes.length, greaterThan(500));
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      expect(ResourceFileService.filename(resource), endsWith('.pdf'));
    }
  });

  test('recap video is an actual playable MP4 asset', () async {
    final resource = CongressCatalog.resources.singleWhere(
      (item) => item.id == 'session-recap',
    );
    final bytes = await ResourceFileService.bytes(resource);
    // The original demo recap contains multiple moving slides, not a single frame.
    expect(bytes.length, greaterThan(5000));
    expect(ascii.decode(bytes.skip(4).take(4).toList()), 'ftyp');
    expect(ResourceFileService.filename(resource), endsWith('.mp4'));
  });

  test('video resources cannot be passed to the PDF generator', () async {
    final video = CongressCatalog.resources.singleWhere(
      (item) => item.kind == ResourceKind.video,
    );
    await expectLater(DemoResourcePdf.build(video), throwsArgumentError);
  });

  test('download resource retains a usable file name and PDF payload', () async {
    final programme = CongressCatalog.resources.singleWhere(
      (resource) => resource.id == 'programme',
    );
    expect(ResourceFileService.filename(programme), 'ntam-programme.pdf');
    final bytes = await ResourceFileService.bytes(programme);
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });
}
