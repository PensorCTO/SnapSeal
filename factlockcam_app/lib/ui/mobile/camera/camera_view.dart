import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/painters/reticle_painter.dart';
import '../../../core/ui/painters/shutter_button_painter.dart';
import '../../../data/supabase/auth_repository.dart';
import '../../../domain/services/vault_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../vault_home_view.dart';
import 'acquisition_mode.dart';
import 'camera_chrome_frame.dart';
import 'telemetry_overlay.dart';

class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key, this.mode = AcquisitionMode.photo, this.onCaptureComplete});

  final AcquisitionMode mode;

  /// Called after the capture completes and the asset is sealed.
  /// When null, falls back to [Navigator.of(context).pop] (standalone route).
  final VoidCallback? onCaptureComplete;

  static const routePath = '/camera';

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isSealing = false;
  bool _isRecording = false;
  int _verifiedFlashTrigger = 0;
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
        setState(() {
          _verifiedFlashTrigger += 1;
        });
        await ref.read(hapticServiceProvider).lock();
        if (!mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 420));
        if (!mounted) return;
      }
      ref.invalidate(dashboardControllerProvider);
      if (!mounted) return;
      setState(() {
        _isSealing = false;
        _isRecording = false;
      });
      widget.onCaptureComplete?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRecording = false;
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onCaptureComplete != null) {
              widget.onCaptureComplete!();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(VaultHomeView.routePath);
            }
          },
        ),
        title: Text(isVideo ? 'Capture video' : 'Capture'),
      ),
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
                              verifiedFlashTrigger: _verifiedFlashTrigger,
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
        verifiedFlashTrigger: _verifiedFlashTrigger,
        onEngageHaptic: () => ref.read(hapticServiceProvider).lock(),
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
      return const ColoredBox(color: AppColors.titaniumDeep);
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
    this.verifiedFlashTrigger = 0,
    this.onEngageHaptic,
  });

  final bool enabled;
  final bool isVideo;
  final bool isRecording;
  final int verifiedFlashTrigger;
  final Future<void> Function()? onEngageHaptic;
  final Future<void> Function() onPressed;

  @override
  State<CameraShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<CameraShutterButton>
    with TickerProviderStateMixin {
  static const _snapDuration = Duration(milliseconds: 170);
  static const _verifiedFlashDuration = Duration(milliseconds: 600);

  late final AnimationController _irisController;
  late final AnimationController _recordController;
  late final AnimationController _verifiedController;
  late final Animation<double> _irisProgress;
  late final Animation<double> _recordFill;
  late final Animation<double> _verifiedFlash;

  @override
  void initState() {
    super.initState();
    _irisController = AnimationController(
      vsync: this,
      duration: _snapDuration,
      reverseDuration: const Duration(milliseconds: 90),
    );
    _recordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _verifiedController = AnimationController(
      vsync: this,
      duration: _verifiedFlashDuration,
    );
    _irisProgress = CurvedAnimation(
      parent: _irisController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeOut,
    );
    _recordFill = CurvedAnimation(
      parent: _recordController,
      curve: Curves.easeOutExpo,
      reverseCurve: Curves.easeOut,
    );
    _verifiedFlash = CurvedAnimation(
      parent: _verifiedController,
      curve: Curves.easeOut,
    );
    _syncRecordingState();
  }

  @override
  void didUpdateWidget(covariant CameraShutterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording ||
        oldWidget.isVideo != widget.isVideo ||
        oldWidget.enabled != widget.enabled) {
      _syncRecordingState();
    }
    if (oldWidget.verifiedFlashTrigger != widget.verifiedFlashTrigger) {
      _verifiedController.forward(from: 0).whenComplete(() {
        if (mounted) {
          _verifiedController.reset();
        }
      });
    }
  }

  @override
  void dispose() {
    _irisController.dispose();
    _recordController.dispose();
    _verifiedController.dispose();
    super.dispose();
  }

  void _syncRecordingState() {
    if (!widget.enabled) {
      _irisController.reverse();
      _recordController.reverse();
      return;
    }
    if (widget.isVideo && widget.isRecording) {
      _irisController.forward();
      _recordController.forward();
    } else {
      _recordController.reverse();
      if (!_irisController.isAnimating) {
        _irisController.reverse();
      }
    }
  }

  void _engagePhotoIris() {
    if (!widget.enabled || widget.isVideo) return;
    _fireEngageHaptic();
    _irisController.forward(from: 0);
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.isVideo) return;
    _releasePhotoIris();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    if (!widget.isVideo) {
      _engagePhotoIris();
      unawaited(widget.onPressed());
      _releasePhotoIris();
      return;
    }
    _fireEngageHaptic();
    unawaited(widget.onPressed());
  }

  void _handleLongPress() {
    if (!widget.enabled || !widget.isVideo) return;
    if (widget.isRecording) {
      unawaited(widget.onPressed());
      return;
    }
    _fireEngageHaptic();
    _irisController.forward(from: 0);
    _recordController.forward(from: 0);
    unawaited(widget.onPressed());
  }

  void _releasePhotoIris() {
    if (!widget.isRecording) {
      _irisController.reverse();
    }
  }

  void _fireEngageHaptic() {
    final haptic = widget.onEngageHaptic;
    if (haptic != null) {
      unawaited(haptic());
    }
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
        onTapCancel: widget.enabled ? _handleTapCancel : null,
        onTap: widget.enabled ? _handleTap : null,
        onLongPress: widget.enabled ? _handleLongPress : null,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: widget.enabled && !widget.isVideo
              ? (_) => _engagePhotoIris()
              : null,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: SizedBox.square(
              dimension: 72,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _irisProgress,
                    _recordFill,
                    _verifiedFlash,
                  ]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ShutterIrisPainter(
                        closeProgress: _irisProgress.value,
                        recordFill: _recordFill.value,
                        verifiedFlash: _verifiedFlash.value,
                      ),
                    );
                  },
                ),
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
              children: [
                const Icon(Icons.shield, color: AppColors.alertAmber, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Sealing...',
                  style: AppTextStyles.monoLg(color: AppColors.starkWhite),
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
