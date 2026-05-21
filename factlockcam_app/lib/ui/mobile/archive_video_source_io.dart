import 'dart:io';
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
  final file = File('${Directory.systemTemp.path}/$assetFingerprint$extension');
  await file.writeAsBytes(bytes, flush: true);

  final controller = VideoPlayerController.file(file);
  await controller.initialize();
  controller.setLooping(true);

  return ArchiveVideoSource(
    controller: controller,
    dispose: () async {
      await controller.dispose();
      if (file.existsSync()) {
        await file.delete();
      }
    },
  );
}
