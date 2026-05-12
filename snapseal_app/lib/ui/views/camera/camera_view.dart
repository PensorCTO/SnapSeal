import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/ui/painters/reticle_painter.dart';
import '../../../core/ui/painters/shutter_button_painter.dart';
import '../../../data/supabase/auth_repository.dart';
import '../../../domain/services/vault_service.dart';
import '../../controllers/dashboard_controller.dart';
import 'acquisition_mode.dart';
import 'camera_chrome_frame.dart';
import 'telemetry_overlay.dart';

class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key, this.mode = AcquisitionMode.photo});

  final AcquisitionMode mode;

  static const routePath = '/camera';

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isSealing = false;
  bool _isRecording = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _onCameraValueChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No available camera found on this device.');
      }
      final preferred = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        preferred,
        ResolutionPreset.high,
        enableAudio: widget.mode == AcquisitionMode.video,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onCameraValueChanged);
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _onShutterPressed() async {
    if (widget.mode == AcquisitionMode.video) {
      if (_isRecording) {
        await _stopAndSealVideo();
      } else {
        await _startVideoRecording();
      }
    } else {
      await _capturePhoto();
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isSealing) {
      return;
    }

    await ref.read(hapticServiceProvider).selectionClick();

    setState(() {
      _isSealing = true;
      _errorMessage = null;
    });

    try {
      final xfile = await controller.takePicture();
      await _sealCapturedFile(xfile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isSealing = false;
      });
    }
  }

  Future<void> _startVideoRecording() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isSealing ||
        _isRecording) {
      return;
    }

    await ref.read(hapticServiceProvider).selectionClick();

    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRecording = false;
      });
    }
  }

  Future<void> _stopAndSealVideo() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isSealing = true;
    });

    try {
      final xfile = await controller.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
      });
      await _sealCapturedFile(xfile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRecording = false;
        _isSealing = false;
      });
    }
  }

  Future<void> _sealCapturedFile(XFile xfile) async {
    try {
      final userId =
          ref.read(supabaseClientProvider)?.auth.currentUser?.id ?? '';
      final result = await ref
          .read(vaultServiceProvider)
          .sealAndStoreCapture(xfile, userId: userId);
      if (!mounted) return;
      if (!result.pendingSync) {
        await ref.read(hapticServiceProvider).heavyImpact();
        if (!mounted) return;
      }
      ref.invalidate(dashboardControllerProvider);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isSealing = false;
      });
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    final wasRecording = _isRecording;
    controller?.removeListener(_onCameraValueChanged);
    _controller = null;
    if (controller != null) {
      // State.dispose() must stay synchronous, so finalize the platform encoder
      // and the controller asynchronously in a chained future. The order
      // `stopVideoRecording` -> `controller.dispose()` is preserved so the
      // encoder flushes its temp file before the session tears down.
      unawaited(_teardownCamera(controller, wasRecording: wasRecording));
    }
    super.dispose();
  }

  static Future<void> _teardownCamera(
    CameraController controller, {
    required bool wasRecording,
  }) async {
    if (wasRecording && controller.value.isInitialized) {
      try {
        await controller.stopVideoRecording();
      } catch (_) {
        // Best-effort: the encoder may already be unwinding; we still want to
        // proceed with controller disposal below.
      }
    }
    await controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = widget.mode == AcquisitionMode.video;
    final controller = _controller;
    final preview = controller?.value.previewSize;
    final previewW = preview?.width.round();
    final previewH = preview?.height.round();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(isVideo ? 'Capture video' : 'Capture')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CameraChromeFrame(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: _buildCameraLayer(theme)),
                  if (_showViewfinder)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: ReticlePainter(
                                guideAspectRatio: isVideo ? 2.35 : 16 / 9,
                              ),
                            ),
                            TelemetryOverlay(
                              acquisitionMode: widget.mode,
                              isRecording: _isRecording,
                              isSealing: _isSealing,
                              previewWidth: previewW,
                              previewHeight: previewH,
                            ),
                            if (_isSealing)
                              const Positioned.fill(child: _SealingOverlay()),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_errorMessage!),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: CameraShutterButton(
        enabled: !_isInitializing && !_isSealing,
        isVideo: isVideo,
        isRecording: _isRecording,
        onPressed: _onShutterPressed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  bool get _showViewfinder {
    if (_isInitializing) return false;
    final c = _controller;
    if (c == null) return false;
    return c.value.isInitialized;
  }

  Widget _buildCameraLayer(ThemeData theme) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_isSealing) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraPreview(_controller!);
  }
}

class CameraShutterButton extends StatefulWidget {
  const CameraShutterButton({
    super.key,
    required this.enabled,
    required this.isVideo,
    required this.isRecording,
    required this.onPressed,
  });

  final bool enabled;
  final bool isVideo;
  final bool isRecording;
  final Future<void> Function() onPressed;

  @override
  State<CameraShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<CameraShutterButton>
    with SingleTickerProviderStateMixin {
  static const _snapDuration = Duration(milliseconds: 150);
  static const _kineticGreen = Color(0xFF00D26A);

  late final AnimationController _fillController;
  late final Animation<double> _fillProgress;
  Color? _fillColor;

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
      vsync: this,
      duration: _snapDuration,
      reverseDuration: const Duration(milliseconds: 90),
    );
    _fillProgress = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeOut,
    );
    _syncRecordingFill();
  }

  @override
  void didUpdateWidget(covariant CameraShutterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording ||
        oldWidget.isVideo != widget.isVideo ||
        oldWidget.enabled != widget.enabled) {
      _syncRecordingFill();
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  void _syncRecordingFill() {
    if (!widget.enabled) {
      _fillColor = null;
      _fillController.reverse();
      return;
    }
    if (widget.isVideo && widget.isRecording) {
      _fillColor = _kineticGreen;
      _fillController.forward();
    } else if (_fillColor == _kineticGreen) {
      _fillController.reverse().whenComplete(() {
        if (mounted && !widget.isRecording) {
          setState(() {
            _fillColor = null;
          });
        }
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.isVideo) return;
    setState(() {
      _fillColor = Colors.white;
    });
    _fillController.forward(from: 0);
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.isVideo) return;
    _releasePhotoFill();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    if (!widget.isVideo) {
      unawaited(widget.onPressed());
      _releasePhotoFill();
      return;
    }
    unawaited(widget.onPressed());
  }

  void _handleLongPress() {
    if (!widget.enabled || !widget.isVideo) return;
    if (widget.isRecording) {
      unawaited(widget.onPressed());
      return;
    }
    setState(() {
      _fillColor = _kineticGreen;
    });
    _fillController.forward(from: 0);
    unawaited(widget.onPressed());
  }

  void _releasePhotoFill() {
    _fillController.reverse().whenComplete(() {
      if (mounted && !widget.isRecording) {
        setState(() {
          _fillColor = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.isVideo
          ? (widget.isRecording ? 'Stop recording' : 'Start recording')
          : 'Capture photo',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? _handleTapDown : null,
        onTapCancel: widget.enabled ? _handleTapCancel : null,
        onTap: widget.enabled ? _handleTap : null,
        onLongPress: widget.enabled ? _handleLongPress : null,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: SizedBox.square(
            dimension: 72,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _fillProgress,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ShutterButtonPainter(
                      fillColor: _fillColor,
                      fillProgress: _fillProgress.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SealingOverlay extends StatelessWidget {
  const _SealingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xEE120014),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.94, end: 1.06),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          onEnd: () {},
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield, color: Colors.amberAccent, size: 64),
                SizedBox(height: 16),
                Text(
                  'Sealing...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(minHeight: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
