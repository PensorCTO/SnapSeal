import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../data/models/archive_item.dart';

part 'send_proof_provider.g.dart';

class SendProofRequest {
  const SendProofRequest({
    required this.item,
    required this.password,
    this.maxDownloads,
    this.linkTtlDays,
  });

  final ArchiveItem item;
  final String password;
  final int? maxDownloads;
  final int? linkTtlDays;
}

class SendProofResult {
  const SendProofResult({
    required this.courierUrl,
    required this.packageId,
    required this.certificatePdfPath,
  });

  final String courierUrl;
  final String packageId;
  final String certificatePdfPath;
}

/// Builds the certificate PDF and courier package for owner-side sharing only.
///
/// Delivery is always via the system share sheet (PDF + link). The app does not
/// send email — that keeps FactLockCam a utility, not a communication service.
@Riverpod(keepAlive: true)
class SendProof extends _$SendProof {
  @override
  FutureOr<SendProofResult?> build() => null;

  Future<SendProofResult> send(SendProofRequest request) async {
    state = const AsyncLoading<SendProofResult?>();
    try {
      final result = await _executeSend(request);
      state = AsyncData<SendProofResult?>(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<SendProofResult?>(error, stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<SendProofResult> _executeSend(SendProofRequest request) async {
    if (!AppConfig.enableProofLinks) {
      throw StateError(
        'Send Proof is not available in this build. Courier links require '
        'ENABLE_PROOF_LINKS=true and a live WEB_ARCHIVE_BASE_URL. '
        'For device QA: set ENABLE_PROOF_LINKS=true in .env.local, run '
        'scripts/sync_flutter_dart_defines.sh, then cold-restart with '
        'run_device.sh or --dart-define-from-file=dart_defines.json.',
      );
    }
    final vaultService = ref.read(vaultServiceProvider);
    final certificateService = ref.read(certificateExportServiceProvider);
    final storage = ref.read(localVaultStorageProvider);

    final resolved = await storage.resolveArchivePaths(request.item);
    final certificateFile = await certificateService.writeCertificatePdfToCache(
      request.item,
      thumbnailPath: resolved.thumbnailPath,
    );

    final courierUrl = await vaultService.createCourierPackage(
      assetHash: request.item.assetFingerprint,
      verifierPassword: request.password,
      maxDownloads: request.maxDownloads,
      linkTtlDays: request.linkTtlDays,
    );

    final packageId = Uri.parse(courierUrl).queryParameters['pkg'];
    if (packageId == null || packageId.isEmpty) {
      throw StateError('Courier package id missing from generated link.');
    }

    return SendProofResult(
      courierUrl: courierUrl,
      packageId: packageId,
      certificatePdfPath: certificateFile.path,
    );
  }
}
