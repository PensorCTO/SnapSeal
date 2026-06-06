import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/di/service_providers.dart';
import '../../core/marketing/approved_pitch.dart';
import '../../core/services/haptic_service.dart';
import '../../core/ui/widgets/archive_panel_navigation_bar.dart';
import '../../data/models/archive_item.dart';
import '../../data/supabase/auth_repository.dart';
import '../../features/archive/presentation/providers/send_proof_provider.dart';
import '../../features/archive_quota/presentation/interceptors/archive_quota_block_reason.dart';
import '../../features/archive_quota/presentation/interceptors/archive_quota_paywall.dart';
import '../../features/archive_quota/presentation/interceptors/metering_credit_interceptor.dart';
import '../../features/archive_quota/presentation/providers/local_archive_quota_gate_provider.dart';
import '../../features/dispatch/presentation/archive_access_control_panel.dart';
import '../../features/dispatch/presentation/dispatch_console_state.dart';
import '../../features/dispatch/presentation/dispatch_error_copy.dart';
import '../../features/dispatch/presentation/secure_comm_consumption_panel.dart';
import '../../features/dispatch/presentation/secure_comm_capture_state.dart';
import 'camera/acquisition_mode.dart';
import 'camera/camera_geolocation_stream.dart';
import 'camera/camera_view.dart';
import 'camera/secure_comm_viewport_frame.dart';
import 'camera/telemetry_overlay.dart';
import '../../../core/ui/painters/reticle_painter.dart';

/// Top-level sync read for [Isolate.run] — async [File.readAsBytes] cannot
/// cross the isolate boundary as a return value.
Uint8List _readSecureCommCaptureBytes(String path) {
  return File(path).readAsBytesSync();
}

/// Zero-Click Secure Comm — live selfie capture, hot lens swap, Archive seal,
/// Access Control overlay, and Send Proof transmission.
class SecureCommCaptureView extends ConsumerStatefulWidget {
  const SecureCommCaptureView({super.key, required this.onBackToHub});

  final VoidCallback onBackToHub;

  @override
  ConsumerState<SecureCommCaptureView> createState() =>
      _SecureCommCaptureViewState();
}

class _SecureCommCaptureViewState extends ConsumerState<SecureCommCaptureView> {
  static const int _videoBytesPerSecondEstimate = 1500000;
  static const Duration _lensSwitchFade = Duration(milliseconds: 150);

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _ownsController = false;
  bool _isInitializing = true;
  bool _isRecording = false;
  bool _isCapturing = false;
  bool _isLensSwitching = false;
  String? _errorMessage;
  Timer? _recordingQuotaTimer;
  DateTime? _recordingStartedAt;
  bool _stoppingForQuotaCap = false;

  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _passwordEmpty = true;

  VideoPlayerController? _previewController;
  File? _previewCacheFile;
  final CameraGeolocationStream _geolocation = CameraGeolocationStream();
  int _verifiedFlashTrigger = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    unawaited(
      _geolocation.start(() {
        if (mounted) setState(() {});
      }),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(secureCommCaptureProvider.notifier).resetToLivePreview();
      unawaited(_initializeCamera());
    });
  }

  void _dismissKeyboard() {
    _passwordFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onPasswordChanged() {
    final empty = _passwordController.text.trim().isEmpty;
    if (empty != _passwordEmpty) {
      setState(() => _passwordEmpty = empty);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final pool = ref.read(secureCommCameraPoolProvider);
      final handoff = pool.adoptController();
      if (handoff != null) {
        _controller = handoff.controller;
        _cameras = handoff.cameras;
        if (_cameras.isEmpty) {
          _cameras = await availableCameras();
        }
        _ownsController = true;
        _controller!.addListener(_onCameraValueChanged);
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = null;
          });
        }
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw StateError('No available camera found on this device.');
      }
      final front = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onCameraValueChanged);
      setState(() {
        _controller = controller;
        _ownsController = true;
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

  void _onCameraValueChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onShutterPressed() async {
    if (_isRecording) {
      await _stopAndAnchor();
    } else {
      await _startVideoRecording();
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
      if (!await ensureArchiveQuotaForSeal(context, ref, incomingBytes: 1)) {
        return;
      }
      await controller.startVideoRecording();
      if (!mounted) return;
      _recordingStartedAt = DateTime.now();
      _recordingQuotaTimer?.cancel();
      _recordingQuotaTimer = Timer.periodic(
        const Duration(milliseconds: 400),
        (_) => unawaited(_pollVideoRecordingQuota()),
      );
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

  Future<void> _stopAndAnchor() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      _recordingQuotaTimer?.cancel();
      _recordingQuotaTimer = null;
      final xfile = await controller.stopVideoRecording();
      if (!mounted) return;

      setState(() => _isRecording = false);
      if (_stoppingForQuotaCap) {
        _stoppingForQuotaCap = false;
        setState(() => _isCapturing = false);
        return;
      }

      await _releaseCameraAfterCapture();

      final previewPath = await _copyPreviewToCache(xfile.path);
      if (!mounted) return;

      final incomingBytes = await File(previewPath).length();
      if (!mounted) return;
      if (!await ensureArchiveQuotaForSeal(
        context,
        ref,
        incomingBytes: incomingBytes,
      )) {
        await _cleanupPreviewCache();
        setState(() => _isCapturing = false);
        unawaited(_initializeCamera());
        return;
      }

      _dismissKeyboard();
      ref
          .read(secureCommCaptureProvider.notifier)
          .beginAnchoring(previewVideoPath: previewPath);

      unawaited(_startPreviewLoop(previewPath));
      unawaited(_anchorCaptureToArchive(previewPath));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isRecording = false;
        _isCapturing = false;
      });
      unawaited(_initializeCamera());
    }
  }

  Future<String> _copyPreviewToCache(String sourcePath) async {
    final tempDir = await getTemporaryDirectory();
    final cacheFile = File(
      p.join(
        tempDir.path,
        'secure_comm_preview_${DateTime.now().microsecondsSinceEpoch}.mp4',
      ),
    );
    await File(sourcePath).copy(cacheFile.path);
    _previewCacheFile = cacheFile;
    return cacheFile.path;
  }

  Future<void> _startPreviewLoop(String path) async {
    await _previewController?.dispose();
    final controller = VideoPlayerController.file(File(path));
    _previewController = controller;
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    await controller.play();
    if (mounted) setState(() {});
  }

  Future<void> _anchorCaptureToArchive(String previewPath) async {
    try {
      final bufferedBytes = await Isolate.run(
        () => _readSecureCommCaptureBytes(previewPath),
      );
      if (!mounted) return;

      final userId =
          ref.read(authRepositoryProvider).currentSession?.user.id ?? '';
      final result = await ref.read(vaultServiceProvider).sealAndStoreCapture(
            XFile(previewPath),
            userId: userId,
            bufferedBytes: bufferedBytes,
          );
      if (!mounted) return;
      if (!result.pendingSync) {
        setState(() => _verifiedFlashTrigger += 1);
        await ref.read(hapticServiceProvider).lock();
        unawaited(recordProProofConsumption(ref));
      }
      ref.invalidate(thumbnailCacheProvider(result.assetFingerprint));
      unawaited(ref.read(dashboardControllerProvider.notifier).refreshArchive());
      ref
          .read(secureCommCaptureProvider.notifier)
          .sealSucceeded(result.assetFingerprint);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      if (message.contains('QuotaExceededException')) {
        await presentArchiveQuotaPaywall(
          context,
          ref,
          reason: ArchiveQuotaBlockReason.storage,
        );
      }
      ref.read(secureCommCaptureProvider.notifier).sealFailed(message);
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pollVideoRecordingQuota() async {
    if (!mounted || !_isRecording || _stoppingForQuotaCap) return;

    final snapshot = ref.read(archiveQuotaNotifierProvider).value;
    final gate = ref.read(localArchiveQuotaGateProvider);
    if (!gate.isFreeTier(snapshot)) return;

    final cap = gate.maxSingleCaptureBytes(snapshot);
    final started = _recordingStartedAt;
    if (started == null) return;

    final elapsedSeconds =
        DateTime.now().difference(started).inMilliseconds / 1000.0;
    final estimatedBytes =
        (elapsedSeconds * _videoBytesPerSecondEstimate).round();
    if (estimatedBytes < cap) return;

    await _stopVideoAtQuotaCap();
  }

  Future<void> _stopVideoAtQuotaCap() async {
    if (_stoppingForQuotaCap || !_isRecording) return;
    _stoppingForQuotaCap = true;
    _recordingQuotaTimer?.cancel();
    _recordingQuotaTimer = null;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _stoppingForQuotaCap = false;
      return;
    }

    try {
      await controller.stopVideoRecording();
    } catch (_) {
      _stoppingForQuotaCap = false;
      return;
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _isCapturing = false;
      _recordingStartedAt = null;
    });
    _stoppingForQuotaCap = false;

    await presentArchiveQuotaPaywall(
      context,
      ref,
      reason: ArchiveQuotaBlockReason.singleCapture,
    );
  }

  Future<void> _flipLens() async {
    final controller = _controller;
    if (controller == null ||
        _isLensSwitching ||
        _isCapturing ||
        _cameras.length < 2 ||
        !controller.value.isInitialized) {
      return;
    }

    setState(() => _isLensSwitching = true);
    try {
      final current = controller.description;
      final other = _cameras.firstWhere(
        (camera) => camera.lensDirection != current.lensDirection,
        orElse: () => current,
      );
      if (other == current) return;

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await controller.setDescription(other);
      HapticFeedback.lightImpact();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLensSwitching = false);
      }
    }
  }

  Future<void> _releaseCameraAfterCapture() async {
    final controller = _controller;
    if (!_ownsController || controller == null) return;

    controller.removeListener(_onCameraValueChanged);
    _controller = null;
    _ownsController = false;
    try {
      await controller.dispose();
    } catch (_) {}
  }

  ArchiveItem? _resolveSealedItem(String? hash) {
    if (hash == null) return null;
    final items = ref.read(dashboardControllerProvider).value ?? const [];
    for (final item in items) {
      if (item.assetFingerprint == hash) {
        return item;
      }
    }
    return null;
  }

  Future<void> _transmitProof() async {
    final capture = ref.read(secureCommCaptureProvider);
    final dispatch = ref.read(dispatchConsoleProvider);
    final password = _passwordController.text.trim();
    final item = _resolveSealedItem(capture.assetFingerprint);

    if (item == null) {
      await _showAlert('Archive item is not ready. Wait for anchoring.');
      return;
    }
    if (password.isEmpty) {
      await _showAlert('Recipient Key is required.');
      return;
    }

    if (!mounted) return;
    if (!await ensureArchiveQuotaForSendProof(context, ref)) {
      return;
    }

    if (!mounted) return;
    unawaited(_showLoadingDialog());

    try {
      final result = await ref.read(sendProofProvider.notifier).send(
            SendProofRequest(
              item: item,
              password: password,
              maxDownloads: dispatch.maxDownloads,
              linkTtlDays: dispatch.linkTtlDays,
            ),
          );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              result.certificatePdfPath,
              mimeType: 'application/pdf',
              name: 'factlockcam-certificate.pdf',
            ),
          ],
          text:
              '$sendProofShareIntro${result.courierUrl}\n\n'
              'Share the password separately.\n\n'
              'Attached: tamper-proof certificate with asset hash and ledger details.',
        ),
      );

      await _cleanupPreviewCache();
      ref.read(secureCommCaptureProvider.notifier).resetToLivePreview();
      widget.onBackToHub();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showTransmitError(friendlyCourierDispatchError(error));
    }
  }

  Future<void> _cleanupPreviewCache() async {
    await _previewController?.dispose();
    _previewController = null;
    final cache = _previewCacheFile;
    _previewCacheFile = null;
    if (cache != null && await cache.exists()) {
      await cache.delete();
    }
  }

  Future<void> _handleBack() async {
    _dismissKeyboard();
    final capture = ref.read(secureCommCaptureProvider);
    if (capture.phase == SecureCommCapturePhase.reviewAndDispatch ||
        capture.phase == SecureCommCapturePhase.anchoringArchive) {
      await _cleanupPreviewCache();
      ref.read(secureCommCaptureProvider.notifier).resetToLivePreview();
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _errorMessage = null;
        });
      }
      unawaited(_initializeCamera());
      return;
    }
    await _disposeCamera();
    widget.onBackToHub();
    unawaited(
      ref.read(secureCommCameraPoolProvider).warmFrontCamera(),
    );
  }

  Future<void> _disposeCamera() async {
    _recordingQuotaTimer?.cancel();
    final controller = _controller;
    final wasRecording = _isRecording;
    if (_ownsController && controller != null) {
      controller.removeListener(_onCameraValueChanged);
      _controller = null;
      _ownsController = false;
      if (wasRecording && controller.value.isInitialized) {
        try {
          await controller.stopVideoRecording();
        } catch (_) {}
      }
      await controller.dispose();
    }
  }

  Future<void> _showAlert(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransmitError(String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Could not transmit proof'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoadingDialog() {
    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CupertinoActivityIndicator(radius: 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _recordingQuotaTimer?.cancel();
    unawaited(_geolocation.stop());
    unawaited(_cleanupPreviewCache());
    if (_ownsController) {
      unawaited(_disposeCamera());
    } else {
      _controller?.removeListener(_onCameraValueChanged);
      _controller = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(secureCommCaptureProvider);
    final dispatch = ref.watch(dispatchConsoleProvider);

    ref.listen<SecureCommCaptureState>(secureCommCaptureProvider, (prev, next) {
      if (prev?.phase != next.phase) {
        _dismissKeyboard();
      }
      if (prev?.canTransmit != true && next.canTransmit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _dismissKeyboard();
        });
      }
    });

    return ColoredBox(
      color: AppColors.titaniumDeep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArchivePanelNavigationBar(
            title: 'SECURE COMM',
            heroTag: 'secure_comm_nav',
            onBack: _handleBack,
          ),
          Expanded(
            child: switch (capture.phase) {
              SecureCommCapturePhase.livePreview => _buildLivePreview(),
              SecureCommCapturePhase.anchoringArchive ||
              SecureCommCapturePhase.reviewAndDispatch =>
                _buildReviewAndDispatch(capture, dispatch),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final controller = _controller;
    final showPreview = !_isInitializing &&
        controller != null &&
        controller.value.isInitialized;
    final preview = controller?.value.previewSize;
    final previewW = preview?.width.round();
    final previewH = preview?.height.round();
    final canFlip =
        _cameras.length > 1 && showPreview && !_isCapturing && !_isLensSwitching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: SecureCommViewportFrame(
              overlay: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isLensSwitching)
                    RepaintBoundary(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: const ColoredBox(color: Colors.transparent),
                      ),
                    ),
                  if (showPreview)
                    RepaintBoundary(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: ReticlePainter(
                              guideAspectRatio: 2.35,
                            ),
                          ),
                          TelemetryOverlay(
                            acquisitionMode: AcquisitionMode.video,
                            isRecording: _isRecording,
                            archivingCount: _isCapturing ? 1 : 0,
                            verifiedFlashTrigger: _verifiedFlashTrigger,
                            previewWidth: previewW,
                            previewHeight: previewH,
                            latitude: _geolocation.latitude,
                            longitude: _geolocation.longitude,
                          ),
                        ],
                      ),
                    ),
                  if (canFlip)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        color: AppColors.titaniumPanel.withValues(alpha: 0.88),
                        onPressed: _flipLens,
                        child: Icon(
                          CupertinoIcons.camera_rotate,
                          size: 20,
                          color: AppColors.starkWhite.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  if (_errorMessage != null && !showPreview)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.monoSm(
                            color: AppColors.starkWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              child: AnimatedOpacity(
                opacity: _isLensSwitching ? 0.35 : 1,
                duration: _lensSwitchFade,
                child: _buildCameraLayer(showPreview),
              ),
            ),
          ),
        ),
        const SecureCommConsumptionPanel(),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
          child: Center(
            child: CameraShutterButton(
              enabled: !_isInitializing && !_isCapturing && showPreview,
              isVideo: true,
              isRecording: _isRecording,
              verifiedFlashTrigger: _verifiedFlashTrigger,
              onEngageHaptic: () => ref.read(hapticServiceProvider).lock(),
              onPressed: _onShutterPressed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraLayer(bool showPreview) {
    if (_isInitializing) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (!showPreview) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraPreview(_controller!);
  }

  Widget _buildReviewAndDispatch(
    SecureCommCaptureState capture,
    DispatchConsoleState dispatch,
  ) {
    final preview = _previewController;
    final canTransmit = capture.canTransmit && !_passwordEmpty;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showPreviewVideo =
        preview != null && preview.value.isInitialized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: SecureCommViewportFrame(
              overlay: Stack(
                fit: StackFit.expand,
                children: [
                  if (capture.phase == SecureCommCapturePhase.anchoringArchive)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _AnchoringBadge(),
                    ),
                  if (capture.errorMessage != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _ErrorBanner(message: capture.errorMessage!),
                    ),
                ],
              ),
              child: showPreviewVideo
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: preview.value.size.width,
                        height: preview.value.size.height,
                        child: VideoPlayer(preview),
                      ),
                    )
                  : const Center(child: CupertinoActivityIndicator()),
            ),
          ),
        ),
        const SecureCommConsumptionPanel(),
        AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + keyboardInset),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ArchiveAccessControlPanel(
                  compact: true,
                  passwordEnabled: capture.canTransmit,
                  passwordController: _passwordController,
                  passwordFocusNode: _passwordFocusNode,
                  obscurePassword: _obscurePassword,
                  onPasswordSubmitted: _dismissKeyboard,
                  onToggleObscurePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  maxDownloads: dispatch.maxDownloads,
                  linkTtlDays: dispatch.linkTtlDays,
                  onMaxDownloadsChanged: (value) {
                    _dismissKeyboard();
                    ref
                        .read(dispatchConsoleProvider.notifier)
                        .setMaxDownloads(value);
                  },
                  onLinkTtlChanged: (value) {
                    _dismissKeyboard();
                    ref
                        .read(dispatchConsoleProvider.notifier)
                        .setLinkTtlDays(value);
                  },
                ),
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: canTransmit ? _transmitProof : null,
                  color: AppColors.kineticGreen,
                  disabledColor: AppColors.titaniumPanel,
                  borderRadius: BorderRadius.zero,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'TRANSMIT PROOF',
                    style: AppTextStyles.monoSm(
                      color: AppColors.titaniumDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnchoringBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.kineticGreen.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Anchoring to Archive…',
          style: AppTextStyles.monoSm(
            color: AppColors.kineticGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.titaniumPanel.withValues(alpha: 0.94),
        border: Border.all(color: CupertinoColors.systemRed.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: AppTextStyles.monoSm(
            color: AppColors.starkWhite.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
