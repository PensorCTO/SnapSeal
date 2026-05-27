import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';

final vaultServiceProvider = Provider<VaultService>(
  (ref) => getIt<VaultService>(),
);

String videoThumbnailTempExtensionForMime(String? mimeType) {
  final normalized = mimeType?.trim().toLowerCase();
  return switch (normalized) {
    'video/quicktime' => '.mov',
    'video/webm' => '.webm',
    'video/3gpp' => '.3gp',
    'video/x-msvideo' => '.avi',
    'video/mpeg' => '.mpeg',
    _ => '.mp4',
  };
}

class ProofLockConflictException implements Exception {
  ProofLockConflictException(this.status);
  final String status;

  @override
  String toString() => 'Proof already exists on ledger (status=$status).';
}

class SealCaptureResult {
  const SealCaptureResult({
    required this.assetFingerprint,
    required this.pendingSync,
    this.chainTxHash,
  });

  final String assetFingerprint;
  final bool pendingSync;
  final String? chainTxHash;
}

class VaultService {
  VaultService({
    required Object database,
    required Object storage,
    required Object secureStorage,
    required Object vaultEncryption,
    required Object sealLedgerRepository,
    required Object chainNotarizer,
    required Object walletService,
    required Object blockchainHandler,
    required Object proofSyncNotifier,
    required Object nativeEnclave,
    required Object authRepository,
    Object? proofCourierService,
    Object? pathResolver,
    Object? transactionalPersister,
    Object? vaultSyncCoordinator,
  });

  Future<String> sealAndStore(
    Uint8List rawMediaBytes, {
    String? mimeType,
    required String userId,
  }) async {
    throw UnsupportedError('Capture sealing is mobile-only.');
  }

  Future<SealCaptureResult> sealAndStoreCapture(
    Object capturedFile, {
    required String userId,
    Uint8List? bufferedBytes,
  }) async {
    throw UnsupportedError('Capture sealing is mobile-only.');
  }

  Future<SealCaptureResult> proofLockFile(
    Object sourceFile,
    String userId,
  ) async {
    throw UnsupportedError('Capture sealing is mobile-only.');
  }

  Future<List<ArchiveItem>> listArchiveItems() async => const [];

  Future<ArchiveItem> regenerateMissingThumbnail(ArchiveItem item) async =>
      item;

  Future<SealedAsset> extractForCourier(String assetFingerprint) async {
    throw UnsupportedError('Local archive extraction is mobile-only.');
  }

  Future<String> createCourierPackage({
    required String assetHash,
    required String verifierPassword,
  }) async {
    throw UnsupportedError('Courier package origination is mobile-only.');
  }

  Future<void> burnLocalWallet() async {}

  Future<bool> retryPendingRemoteSync(String assetFingerprint) async => false;

  Future<void> updateArchiveMetadata({
    required String assetFingerprint,
    required String? title,
    required String? description,
  }) async {}

  Future<void> deleteArchiveItem(String assetFingerprint) async {}
}
