// Web-only blob URLs for courier playback (same pattern as cipher_engine_web.dart).
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import 'courier_media_playback.dart';

Future<CourierMediaPlayback?> createCourierMediaPlayback({
  required Uint8List bytes,
  required String? fileExtension,
  required String? contentMimeType,
}) async {
  final ext = (fileExtension ?? '').replaceFirst('.', '').toLowerCase();
  final isImage = {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);
  if (isImage) {
    return CourierMediaPlayback(
      controller: null,
      isVideo: false,
      dispose: () async {},
    );
  }

  final mime = _resolveMime(ext, contentMimeType);
  final blob = html.Blob([bytes], mime);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final controller = VideoPlayerController.networkUrl(Uri.parse(objectUrl));
  await controller.initialize();
  await controller.setLooping(false);

  return CourierMediaPlayback(
    controller: controller,
    isVideo: true,
    dispose: () async {
      await controller.dispose();
      html.Url.revokeObjectUrl(objectUrl);
    },
  );
}

String _resolveMime(String ext, String? contentMimeType) {
  if (contentMimeType != null && contentMimeType.isNotEmpty) {
    return contentMimeType;
  }
  switch (ext) {
    case 'mov':
      return 'video/quicktime';
    case 'webm':
      return 'video/webm';
    case 'mp3':
    case 'm4a':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    default:
      return 'video/mp4';
  }
}
