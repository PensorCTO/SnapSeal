import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import 'courier_web_media_source.dart';

class CourierMediaStage extends StatefulWidget {
  const CourierMediaStage({
    super.key,
    required this.bytes,
    required this.fileExtension,
    required this.contentMimeType,
    required this.onPlaybackCompleted,
  });

  final Uint8List bytes;
  final String? fileExtension;
  final String? contentMimeType;
  final VoidCallback onPlaybackCompleted;

  @override
  State<CourierMediaStage> createState() => _CourierMediaStageState();
}

class _CourierMediaStageState extends State<CourierMediaStage> {
  CourierMediaPlayback? _playback;
  bool _loading = true;
  String? _error;
  Timer? _imageCtaTimer;
  bool _completionNotified = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final playback = await createCourierMediaPlayback(
        bytes: widget.bytes,
        fileExtension: widget.fileExtension,
        contentMimeType: widget.contentMimeType,
      );

      if (!mounted) {
        await playback?.dispose();
        return;
      }

      final ext = (widget.fileExtension ?? '').replaceFirst('.', '');
      final isImage = {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);

      setState(() {
        _playback = playback;
        _loading = false;
      });

      if (isImage) {
        _imageCtaTimer = Timer(const Duration(seconds: 8), _notifyCompletedOnce);
        return;
      }

      final controller = playback?.controller;
      if (controller != null) {
        controller.addListener(_onVideoTick);
        await controller.play();
      } else {
        _notifyCompletedOnce();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _onVideoTick() {
    final controller = _playback?.controller;
    if (controller == null) return;
    final value = controller.value;
    if (!value.isInitialized) return;
    final duration = value.duration;
    if (duration <= Duration.zero) return;
    if (value.position >= duration - const Duration(milliseconds: 250)) {
      _notifyCompletedOnce();
    }
  }

  void _notifyCompletedOnce() {
    if (_completionNotified) return;
    _completionNotified = true;
    widget.onPlaybackCompleted();
  }

  @override
  void dispose() {
    _imageCtaTimer?.cancel();
    final playback = _playback;
    if (playback?.controller != null) {
      playback!.controller!.removeListener(_onVideoTick);
    }
    playback?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null) {
      return Text(
        _error!,
        style: AppTextStyles.monoSm(color: AppColors.alertAmber),
      );
    }

    final ext = (widget.fileExtension ?? '').replaceFirst('.', '');
    final isImage = {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);
    final controller = _playback?.controller;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.verifiedNeon.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: isImage
              ? Image.memory(widget.bytes, fit: BoxFit.contain)
              : controller != null && controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Verified ${ext.isEmpty ? 'asset' : '.$ext asset'} '
                        '(${widget.bytes.length} bytes). '
                        'Preview support for this type is not enabled yet.',
                        style: AppTextStyles.monoMd(),
                      ),
                    ),
        ),
      ),
    );
  }
}
