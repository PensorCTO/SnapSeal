import 'package:video_player/video_player.dart';

/// Web courier media handle (image or blob-backed video/audio).
class CourierMediaPlayback {
  const CourierMediaPlayback({
    required this.controller,
    required this.dispose,
    required this.isVideo,
  });

  final VideoPlayerController? controller;
  final Future<void> Function() dispose;
  final bool isVideo;
}
