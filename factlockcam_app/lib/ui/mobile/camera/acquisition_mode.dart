/// Capture intent passed from the vault dashboard into [CameraView].
///
/// The blueprint's "Capture Layer: Strict Provenance" routes both modes
/// through the same `VaultService.sealAndStoreCapture` pipeline; only the
/// in-camera UX (single tap vs start/stop, audio enable) differs.
enum AcquisitionMode {
  photo,
  video;

  static AcquisitionMode parse(String? raw) {
    if (raw == null) return AcquisitionMode.photo;
    if (raw.toLowerCase() == 'video') return AcquisitionMode.video;
    return AcquisitionMode.photo;
  }

  String get queryValue => name;
}
