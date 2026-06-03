/// User-visible copy for archive hub, omni-surface, and inspector.
///
/// Centralized literals for compliance tests (`marketing_compliance_test`,
/// `presentation_archive_copy_test`).
class ArchivePresentationCopy {
  const ArchivePresentationCopy._();

  static const inspectorSendProof = 'SEND PROOF';
  static const inspectorViewPlay = 'VIEW/PLAY MEDIA';
  static const inspectorDownload = 'DOWNLOAD MEDIA';
  static const inspectorCertificate = 'VIEW CERTIFICATE';
  static const inspectorDelete = 'DELETE FROM DEVICE';
  static const inspectorBack = 'BACK TO ARCHIVE';

  static const emptyNoSealedAssets = 'NO SEALED ASSETS';
  static const emptyCaptureHint = 'Capture a photo or video to begin.';

  static const List<String> curatedUserVisible = [
    inspectorSendProof,
    inspectorViewPlay,
    inspectorDownload,
    inspectorCertificate,
    inspectorDelete,
    inspectorBack,
    emptyNoSealedAssets,
    emptyCaptureHint,
  ];
}
