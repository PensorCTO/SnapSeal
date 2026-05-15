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
  throw UnsupportedError('Archive video playback is mobile-only.');
}
