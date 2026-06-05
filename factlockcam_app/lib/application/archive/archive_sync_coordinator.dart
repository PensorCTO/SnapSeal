import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart' as crypto;

import '../../core/archive/domain/archive_content_category.dart';
import '../../core/archive/domain/mime_extension_map.dart';
import '../../core/config/app_config.dart';
import '../../core/cloud/supabase_archive_service.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/archive_encryption_handler.dart';
import '../../core/errors/exceptions.dart';
import '../../core/platform/platform_channel_coordinator.dart';
import '../../data/supabase/seal_ledger_repository.dart';

/// Result of a post-notarization cloud vault synchronization attempt.
class CloudArchiveSyncOutcome {
  const CloudArchiveSyncOutcome({
    required this.uploaded,
    this.storagePath,
    this.packageId,
    this.quotaExceeded = false,
    this.skipped = false,
  });

  const CloudArchiveSyncOutcome.skipped()
      : uploaded = false,
        storagePath = null,
        packageId = null,
        quotaExceeded = false,
        skipped = true;

  final bool uploaded;
  final String? storagePath;
  final String? packageId;
  final bool quotaExceeded;
  final bool skipped;
}

/// Coordinates proof-lock sequencing: ledger commit → isolate encrypt → background upload.
class ArchiveSyncCoordinator {
  ArchiveSyncCoordinator({
    required SealLedgerRepository sealLedgerRepository,
    required SupabaseArchiveService vaultService,
    required IPlatformChannelCoordinator channelCoordinator,
  })  : _sealLedgerRepository = sealLedgerRepository,
        _vaultService = vaultService,
        _channelCoordinator = channelCoordinator;

  final SealLedgerRepository _sealLedgerRepository;
  final SupabaseArchiveService _vaultService;
  final IPlatformChannelCoordinator _channelCoordinator;

  /// Runs after local WAL persistence and proof_ledger anchoring, before source unlink.
  Future<CloudArchiveSyncOutcome> syncAfterNotarization({
    required File rawSourceFile,
    required String assetHash,
    required String mimeType,
    required String userId,
    required String encodedVaultKey,
    required String cloudSealPassword,
  }) async {
    if (!_sealLedgerRepository.isConfigured || userId.trim().isEmpty) {
      return const CloudArchiveSyncOutcome.skipped();
    }
    if (!await rawSourceFile.exists()) {
      return const CloudArchiveSyncOutcome.skipped();
    }

    final fileSize = await rawSourceFile.length();
    if (fileSize > SupabaseArchiveService.maxUploadBytes) {
      return CloudArchiveSyncOutcome(
        uploaded: false,
        quotaExceeded: true,
      );
    }

    final fileExtension = fileExtensionForMimeType(mimeType);
    final contentCategory = categoryFromMime(mimeType);
    contentCategory.assertConsumerSupported(
      arbitraryFileSealEnabled: AppConfig.enableArbitraryFileSeal,
    );
    final provisionalPath = _normalizedStoragePath(
      '$userId/vault/$assetHash.pending',
    );

    final packageId = await _sealLedgerRepository.getOrCreateCourierPackage(
      assetHash: assetHash,
      verifierPassword: _internalCloudVerifier(assetHash),
      encodedVaultKey: encodedVaultKey,
      fileExtension: fileExtension,
      storagePath: provisionalPath,
      contentMimeType: mimeType,
      contentCategory: contentCategory.rpcValue,
    );

    final storagePath = _normalizedStoragePath('$userId/$packageId.enc');
    final filePath = rawSourceFile.path;
    final password = cloudSealPassword;

    try {
      final encryptedBytes = await Isolate.run(() async {
        final plaintext = await File(filePath).readAsBytes();
        return CourierCrypto.encrypt(
          plaintext,
          password,
          vault: DefaultArchiveEncryptionHandler(),
        );
      });

      await _channelCoordinator.executeWithBackgroundScope(() {
        return _vaultService.uploadEncryptedAsset(
          encryptedBytes: encryptedBytes,
          packageId: packageId,
          storagePath: storagePath,
          plaintextFileSizeBytes: fileSize,
        );
      });

      return CloudArchiveSyncOutcome(
        uploaded: true,
        storagePath: storagePath,
        packageId: packageId,
      );
    } on QuotaExceededException {
      return const CloudArchiveSyncOutcome(
        uploaded: false,
        quotaExceeded: true,
      );
    }
  }

  static String _internalCloudVerifier(String assetHash) {
    return crypto.sha256
        .convert(utf8.encode('factlockcam:cloud-vault:${assetHash.trim()}'))
        .toString();
  }

  static String _normalizedStoragePath(String raw) {
    var path = raw.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    return path;
  }

}
