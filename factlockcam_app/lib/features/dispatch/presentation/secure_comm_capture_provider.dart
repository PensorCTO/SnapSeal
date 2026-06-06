import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_comm_capture_state.dart';

final secureCommCaptureProvider =
    NotifierProvider<SecureCommCaptureNotifier, SecureCommCaptureState>(
  SecureCommCaptureNotifier.new,
);

class SecureCommCaptureNotifier extends Notifier<SecureCommCaptureState> {
  @override
  SecureCommCaptureState build() => const SecureCommCaptureState();

  void resetToLivePreview() {
    state = const SecureCommCaptureState();
  }

  void beginAnchoring({required String previewVideoPath}) {
    state = state.copyWith(
      phase: SecureCommCapturePhase.anchoringArchive,
      previewVideoPath: previewVideoPath,
      clearError: true,
    );
  }

  void sealSucceeded(String assetFingerprint) {
    state = state.copyWith(
      phase: SecureCommCapturePhase.reviewAndDispatch,
      assetFingerprint: assetFingerprint,
      clearError: true,
    );
  }

  void sealFailed(String message) {
    state = state.copyWith(
      phase: SecureCommCapturePhase.reviewAndDispatch,
      errorMessage: message,
    );
  }
}
