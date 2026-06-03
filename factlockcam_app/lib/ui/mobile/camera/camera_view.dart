import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/di/service_providers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/widgets/vault_panel_navigation_bar.dart';
import '../../../core/ui/painters/reticle_painter.dart';
import '../../../core/ui/painters/shutter_button_painter.dart';
import '../../../data/supabase/auth_repository.dart';
import '../../../domain/services/vault_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../vault/providers/thumbnail_cache_provider.dart';
import '../vault_home_view.dart';
import '../../../features/archive_quota/presentation/interceptors/metering_credit_interceptor.dart';
import 'acquisition_mode.dart';
import 'camera_chrome_frame.dart';
import 'camera_geolocation_stream.dart';
import 'telemetry_overlay.dart';

class CameraView extends ConsumerStatefulWidget {
  const CameraView({
    super.key,
    this.mode = AcquisitionMode.photo,
    this.onCaptureComplete,
    this.onBackToHub,
  });

  final AcquisitionMode mode;

  /// Called after the capture completes and the asset is sealed.
  /// When null, falls back to [Navigator.of(context).pop] (standalone route).
  final VoidCallback? onCaptureComplete;

  /// When set (archive shell), back navigates to the hub instead of popping a route.
  final VoidCallback? onBackToHub;

  static const routePath = '/camera';

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> {
  CameraController? _controller;
  bool _isInitializing = true;
  int _archivingCount = 0;
  bool _isCapturing = false;
  bool _isRecording = false;
  int _verifiedFlashTrigger = 0;
  String? _errorMessage;
  final CameraGeolocationStream _geolocation = CameraGeolocationStream();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    unawaited(
      _geolocation.start(() {
        if (mounted) setState(() {});
      }),
    );
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
        imageFormatGroup: widget.mode == AcquisitionMode.photo
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
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
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _archivingCount > 4) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final xfile = await controller.takePicture();
      final bufferedBytes = await xfile.readAsBytes();
      unawaited(_sealCapturedFile(xfile, bufferedBytes: bufferedBytes));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _startVideoRecording() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
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
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final xfile = await controller.stopVideoRecording();
      final bufferedBytes = await xfile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isCapturing = false;
      });
      unawaited(_sealCapturedFile(xfile, bufferedBytes: bufferedBytes));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRecording = false;
        _isCapturing = false;
      });
    }
  }

  Future<void> _sealCapturedFile(
    XFile xfile, {
    required Uint8List bufferedBytes,
  }) async {
    if (!mounted) return;
    setState(() {
      _archivingCount += 1;
    });

    try {
      final userId =
          ref.read(supabaseClientProvider)?.auth.currentUser?.id ?? '';
      final result = await ref
          .read(vaultServiceProvider)
          .sealAndStoreCapture(
            xfile,
            userId: userId,
            bufferedBytes: bufferedBytes,
          );
      if (!mounted) return;
      if (!result.pendingSync) {
        setState(() {
          _verifiedFlashTrigger += 1;
        });
        await ref.read(hapticServiceProvider).lock();
        unawaited(recordProProofConsumption(ref));
      }
      ref.invalidate(thumbnailCacheProvider(result.assetFingerprint));
      await ref.read(dashboardControllerProvider.notifier).refreshArchive();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRecording = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _archivingCount = (_archivingCount - 1).clamp(0, 999);
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_geolocation.stop());
    final controller = _controller;
    final wasRecording = _isRecording;
    controller?.removeListener(_onCameraValueChanged);
    _controller = null;
    if (controller != null) {
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
      } catch (_) {}
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

    void onBackPressed() {
      if (widget.onBackToHub != null) {
        widget.onBackToHub!();
      } else if (widget.onCaptureComplete != null) {
        widget.onCaptureComplete!();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go(VaultHomeView.routePath);
      }
    }

    final previewStack = Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
      child: Stack(
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
                              archivingCount: _archivingCount,
                              verifiedFlashTrigger: _verifiedFlashTrigger,
                              previewWidth: previewW,
                              previewHeight: previewH,
                              latitude: _geolocation.latitude,
                              longitude: _geolocation.longitude,
                            ),
                            if (_archivingCount > 0)
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: _ArchivingBadge(count: _archivingCount),
                              ),
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
    );

    final shutter = CameraShutterButton(
      enabled: !_isInitializing && !_isCapturing,
      isVideo: isVideo,
      isRecording: _isRecording,
      verifiedFlashTrigger: _verifiedFlashTrigger,
      onEngageHaptic: () => ref.read(hapticServiceProvider).lock(),
      onPressed: _onShutterPressed,
    );

    if (widget.onBackToHub != null) {
      return CupertinoPageScaffold(
        backgroundColor: Colors.black,
        navigationBar: VaultPanelNavigationBar(
          title: isVideo ? 'Video' : 'Picture',
          onBack: onBackPressed,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            previewStack,
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(child: shutter),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
        title: Text(isVideo ? 'Capture video' : 'Capture'),
      ),
      body: previewStack,
      floatingActionButton: shutter,
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
    return CameraPreview(_controller!);
  }
}

class _ArchivingBadge extends StatelessWidget {
  const _ArchivingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.kineticGreen.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Archiving Asset… [$count]',
          style: AppTextStyles.monoSm(
            color: AppColors.kineticGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
