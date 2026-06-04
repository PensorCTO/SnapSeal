import '../../../core/config/app_config.dart';

/// Future institution-grade file ingress (not wired in consumer DI).
abstract class ArchiveIngressPort {
  Future<SealCaptureInput> readPayload();
}

/// Input descriptor for the seal pipeline (camera or file picker).
class SealCaptureInput {
  const SealCaptureInput({
    required this.sourcePath,
    this.mimeType,
    this.displayName,
  });

  final String sourcePath;
  final String? mimeType;
  final String? displayName;
}

/// Placeholder for institution-grade arbitrary file import.
class FileArchiveIngress implements ArchiveIngressPort {
  const FileArchiveIngress();

  @override
  Future<SealCaptureInput> readPayload() {
    if (!AppConfig.enableArbitraryFileSeal) {
      throw UnsupportedError(
        'Arbitrary file sealing is disabled. Set ENABLE_ARBITRARY_FILE_SEAL=true '
        'in institution-grade builds.',
      );
    }
    throw UnimplementedError('FileArchiveIngress is not implemented yet.');
  }
}
