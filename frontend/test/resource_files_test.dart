import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ntam_congress_demo/features/congress/data/congress_catalog.dart';
import 'package:ntam_congress_demo/features/congress/domain/congress_models.dart';
import 'package:ntam_congress_demo/features/resources/data/demo_resource_pdf.dart';
import 'package:ntam_congress_demo/features/resources/data/resource_file_service.dart';
import 'package:ntam_congress_demo/features/resources/data/resource_video_links.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('three original document resources generate real PDF bytes', () async {
    final documents = CongressCatalog.resources.where(
      (resource) => resource.kind != ResourceKind.video);
    expect(documents.length, 3);
    for (final resource in documents) {
      final bytes = await ResourceFileService.bytes(resource);
      expect(bytes.length, greaterThan(500));
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      expect(ResourceFileService.filename(resource), endsWith('.pdf'));
    }
  });

  test('Stanford resource links to public YouTube course trailer', () {
    final video = CongressCatalog.resources.singleWhere(
      (resource) => resource.id == 'session-recap',
    );
    expect(video.kind, ResourceKind.video);
    expect(video.title, 'Introduction to Food & Health');
    expect(ResourceVideoLinks.forResource(video.id).toString(),
        'https://www.youtube.com/watch?v=z7x1aaZ03xU');
    expect(ResourceVideoLinks.forResource('programme'), isNull);
    expect(video.availabilityLabel, contains('YouTube'));
  });

  test('third-party video is never packaged as an MP4 or PDF', () async {
    final video = CongressCatalog.resources.singleWhere(
      (resource) => resource.kind == ResourceKind.video,
    );
    expect(() => ResourceFileService.filename(video), throwsUnsupportedError);
    expect(() => ResourceFileService.bytes(video), throwsUnsupportedError);
    await expectLater(DemoResourcePdf.build(video), throwsArgumentError);
  });

  test('download retains expected PDF file name', () {
    final resource = CongressCatalog.resources.singleWhere(
      (resource) => resource.id == 'programme',
    );
    expect(ResourceFileService.filename(resource), 'ntam-programme.pdf');
  });
}
