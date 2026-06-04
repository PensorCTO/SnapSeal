import 'package:flutter_test/flutter_test.dart';

import 'package:factlockcam/core/archive/domain/archive_content_category.dart';
import 'package:factlockcam/core/archive/domain/mime_extension_map.dart';

void main() {
  group('categoryFromMime', () {
    test('maps consumer capture MIME types', () {
      expect(categoryFromMime('image/jpeg'), ArchiveContentCategory.image);
      expect(categoryFromMime('video/mp4'), ArchiveContentCategory.video);
      expect(categoryFromMime('image/jpeg').isConsumerSupported, isTrue);
      expect(categoryFromMime('video/mp4').isConsumerSupported, isTrue);
    });

    test('classifies institution-grade MIME without consumer support', () {
      expect(
        categoryFromMime('application/pdf'),
        ArchiveContentCategory.document,
      );
      expect(
        categoryFromMime('application/pdf').isConsumerSupported,
        isFalse,
      );
      expect(categoryFromMime('audio/mpeg'), ArchiveContentCategory.audio);
    });

    test('rpcValue matches SQL check constraint names', () {
      expect(ArchiveContentCategory.image.rpcValue, 'image');
      expect(ArchiveContentCategory.video.rpcValue, 'video');
    });
  });

  group('fileExtensionForMimeType', () {
    test('resolves image and video extensions', () {
      expect(fileExtensionForMimeType('image/png'), '.png');
      expect(fileExtensionForMimeType('video/quicktime'), '.mov');
      expect(fileExtensionForMimeType('video/mp4'), '.mp4');
    });
  });
}
