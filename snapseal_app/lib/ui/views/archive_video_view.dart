import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/archive_item.dart';
import '../../domain/services/vault_service.dart';

class ArchiveVideoView extends ConsumerStatefulWidget {
  const ArchiveVideoView({super.key, required this.item});

  final ArchiveItem item;

  @override
  ConsumerState<ArchiveVideoView> createState() => _ArchiveVideoViewState();
}

class _ArchiveVideoViewState extends ConsumerState<ArchiveVideoView> {
  VideoPlayerController? _controller;
  File? _tempFile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepareVideo();
  }

  Future<void> _prepareVideo() async {
    try {
      final sealed = await ref
          .read(vaultServiceProvider)
          .extractForCourier(widget.item.assetFingerprint);
      final extension = _extensionFromMime(widget.item.mimeType);
      final file = File(
        '${Directory.systemTemp.path}/${widget.item.assetFingerprint}$extension',
      );
      await file.writeAsBytes(sealed.bytes, flush: true);

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        await controller.dispose();
        if (file.existsSync()) {
          await file.delete();
        }
        return;
      }

      setState(() {
        _tempFile = file;
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _extensionFromMime(String? mimeType) {
    if (mimeType == null) {
      return '.mp4';
    }
    if (mimeType.contains('quicktime')) {
      return '.mov';
    }
    if (mimeType.contains('webm')) {
      return '.webm';
    }
    return '.mp4';
  }

  @override
  void dispose() {
    _controller?.dispose();
    final file = _tempFile;
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title ?? 'Video'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  )
                : controller == null
                    ? const Text('Video unavailable')
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                          const SizedBox(height: 16),
                          IconButton.filled(
                            onPressed: () {
                              if (controller.value.isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
