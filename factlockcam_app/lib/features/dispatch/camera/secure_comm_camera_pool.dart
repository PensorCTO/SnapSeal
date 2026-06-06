import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Pre-warmed front camera for instant Secure Comm entry.
class SecureCommCameraHandoff {
  const SecureCommCameraHandoff({
    required this.controller,
    required this.cameras,
  });

  final CameraController controller;
  final List<CameraDescription> cameras;
}

class SecureCommCameraPool {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _warming = false;

  List<CameraDescription> get cachedCameras => List.unmodifiable(_cameras);

  bool get hasReadyController =>
      _controller != null && _controller!.value.isInitialized;

  /// Best-effort front-camera init while the hub is visible.
  Future<void> warmFrontCamera() async {
    if (kIsWeb) return;
    if (hasReadyController) return;
    if (_warming) return;

    _warming = true;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

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

      final previous = _controller;
      _controller = controller;
      if (previous != null) {
        await previous.dispose();
      }
    } catch (_) {
      // Pre-warm is best-effort (simulator, permission denied, etc.).
    } finally {
      _warming = false;
    }
  }

  /// Transfers ownership of the pre-warmed controller to the capture view.
  SecureCommCameraHandoff? adoptController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }
    _controller = null;
    return SecureCommCameraHandoff(
      controller: controller,
      cameras: _cameras,
    );
  }

  Future<void> release() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;

    if (controller.value.isRecordingVideo) {
      try {
        await controller.stopVideoRecording();
      } catch (_) {}
    }
    await controller.dispose();
  }
}
