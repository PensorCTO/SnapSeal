/// Phases for the Zero-Click Secure Comm capture flow.
enum SecureCommCapturePhase {
  livePreview,
  anchoringArchive,
  reviewAndDispatch,
}

/// Riverpod-held capture outcome after seal completes.
class SecureCommCaptureState {
  const SecureCommCaptureState({
    this.phase = SecureCommCapturePhase.livePreview,
    this.assetFingerprint,
    this.previewVideoPath,
    this.errorMessage,
  });

  final SecureCommCapturePhase phase;
  final String? assetFingerprint;
  final String? previewVideoPath;
  final String? errorMessage;

  bool get canTransmit =>
      phase == SecureCommCapturePhase.reviewAndDispatch &&
      assetFingerprint != null &&
      assetFingerprint!.isNotEmpty;

  SecureCommCaptureState copyWith({
    SecureCommCapturePhase? phase,
    String? assetFingerprint,
    bool clearAssetFingerprint = false,
    String? previewVideoPath,
    bool clearPreviewVideoPath = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SecureCommCaptureState(
      phase: phase ?? this.phase,
      assetFingerprint: clearAssetFingerprint
          ? null
          : (assetFingerprint ?? this.assetFingerprint),
      previewVideoPath: clearPreviewVideoPath
          ? null
          : (previewVideoPath ?? this.previewVideoPath),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
