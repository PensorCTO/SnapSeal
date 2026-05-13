import 'package:flutter_test/flutter_test.dart';
import 'package:snapseal/domain/services/vault_service.dart';

void main() {
  test('video thumbnail temp extension follows MIME type', () {
    expect(videoThumbnailTempExtensionForMime('video/quicktime'), '.mov');
    expect(videoThumbnailTempExtensionForMime('video/webm'), '.webm');
    expect(videoThumbnailTempExtensionForMime('video/mp4'), '.mp4');
  });

  test('video thumbnail temp extension defaults safely for unknown MIME', () {
    expect(videoThumbnailTempExtensionForMime(null), '.mp4');
    expect(videoThumbnailTempExtensionForMime(''), '.mp4');
    expect(videoThumbnailTempExtensionForMime('video/unknown'), '.mp4');
  });
}
