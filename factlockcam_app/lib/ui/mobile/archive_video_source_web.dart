// Web-only blob URLs for in-browser archive video preview.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

class ArchiveVideoSource {
  const ArchiveVideoSource({required this.controller, required this.dispose});

  final VideoPlayerController controller;
  final Future<void> Function() dispose;
}

Future<ArchiveVideoSource> createArchiveVideoSource({
  required Uint8List bytes,
  required String assetFingerprint,
  required String extension,
}) async {
  final mime = extension.toLowerCase().contains('mov')
      ? 'video/quicktime'
      : extension.toLowerCase().contains('webm')
          ? 'video/webm'
          : 'video/mp4';
  final blob = html.Blob([bytes], mime);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final controller = VideoPlayerController.networkUrl(Uri.parse(objectUrl));
  await controller.initialize();
  controller.setLooping(true);

  return ArchiveVideoSource(
    controller: controller,
    dispose: () async {
      await controller.dispose();
      html.Url.revokeObjectUrl(objectUrl);
    },
  );
}
