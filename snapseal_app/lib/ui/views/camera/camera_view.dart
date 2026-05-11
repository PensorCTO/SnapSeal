import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../data/supabase/auth_repository.dart';
import '../../../domain/services/vault_service.dart';
import '../../controllers/dashboard_controller.dart';
import 'acquisition_mode.dart';

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
      final userId = ref.read(supabaseClientProvider)?.auth.currentUser?.id ?? '';
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
    if (controller != null) {
      // Best-effort: stop a still-running recording before disposal so the
      // platform encoder doesn't leak the temp file.
      if (_isRecording && controller.value.isInitialized) {
        controller.stopVideoRecording().catchError((_) => XFile(''));
      }
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = widget.mode == AcquisitionMode.video;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isVideo ? 'Capture video' : 'Capture'),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraLayer(theme)),
          if (_isRecording)
            const Positioned(
              top: 16,
              left: 16,
              child: _RecordingIndicator(),
            ),
          if (_isSealing)
            const Positioned.fill(
              child: RepaintBoundary(child: _SealingOverlay()),
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
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isInitializing || _isSealing ? null : _onShutterPressed,
        backgroundColor: _isRecording ? Colors.redAccent : null,
        child: Icon(_shutterIcon(isVideo: isVideo, recording: _isRecording)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  IconData _shutterIcon({required bool isVideo, required bool recording}) {
    if (!isVideo) return Icons.camera_alt;
    return recording ? Icons.stop : Icons.fiber_manual_record;
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
    return RepaintBoundary(child: CameraPreview(_controller!));
  }
}

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 14),
          SizedBox(width: 6),
          Text(
            'REC',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
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
