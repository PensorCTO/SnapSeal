import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/archive_item.dart';
import '../../domain/services/vault_service.dart';
import 'archive_video_source.dart';

class ArchiveVideoView extends ConsumerStatefulWidget {
  const ArchiveVideoView({super.key, required this.item});

  final ArchiveItem item;

  @override
  ConsumerState<ArchiveVideoView> createState() => _ArchiveVideoViewState();
}

class _ArchiveVideoViewState extends ConsumerState<ArchiveVideoView> {
  VideoPlayerController? _controller;
  Future<void> Function()? _disposeSource;
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
      final source = await createArchiveVideoSource(
        bytes: sealed.bytes,
        assetFingerprint: widget.item.assetFingerprint,
        extension: extension,
      );

      if (!mounted) {
        await source.dispose();
        return;
      }

      setState(() {
        _disposeSource = source.dispose;
        _controller = source.controller;
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
    final disposeSource = _disposeSource;
    if (disposeSource != null) {
      disposeSource();
    } else {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title ?? 'Video')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
            ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!))
            : controller == null
            ? const Text('Video unavailable')
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final aspect = controller.value.aspectRatio <= 0
                                ? 16 / 9
                                : controller.value.aspectRatio;
                            var width = constraints.maxWidth;
                            var height = width / aspect;
                            if (height > constraints.maxHeight) {
                              height = constraints.maxHeight;
                              width = height * aspect;
                            }

                            return Center(
                              child: SizedBox(
                                width: width,
                                height: height,
                                child: VideoPlayer(controller),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
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
              ),
      ),
    );
  }
}
