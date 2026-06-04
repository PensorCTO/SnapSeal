import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart' as crypto;

import '../../core/archive/domain/archive_content_category.dart';
import '../../core/archive/domain/mime_extension_map.dart';
import '../../core/config/app_config.dart';
import '../../core/cloud/supabase_vault_service.dart';
import '../../core/crypto/courier_crypto.dart';
import '../../core/crypto/vault_encryption_handler.dart';
import '../../core/errors/exceptions.dart';
import '../../core/platform/platform_channel_coordinator.dart';
import '../../data/supabase/seal_ledger_repository.dart';

/// Result of a post-notarization cloud vault synchronization attempt.
class CloudVaultSyncOutcome {
  const CloudVaultSyncOutcome({
    required this.uploaded,
    this.storagePath,
    this.packageId,
    this.quotaExceeded = false,
    this.skipped = false,
  });

  const CloudVaultSyncOutcome.skipped()
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
class VaultSyncCoordinator {
  VaultSyncCoordinator({
    required SealLedgerRepository sealLedgerRepository,
    required SupabaseVaultService vaultService,
    required IPlatformChannelCoordinator channelCoordinator,
  })  : _sealLedgerRepository = sealLedgerRepository,
        _vaultService = vaultService,
        _channelCoordinator = channelCoordinator;

  final SealLedgerRepository _sealLedgerRepository;
  final SupabaseVaultService _vaultService;
  final IPlatformChannelCoordinator _channelCoordinator;

  /// Runs after local WAL persistence and proof_ledger anchoring, before source unlink.
  Future<CloudVaultSyncOutcome> syncAfterNotarization({
    required File rawSourceFile,
    required String assetHash,
    required String mimeType,
    required String userId,
    required String encodedVaultKey,
    required String cloudSealPassword,
  }) async {
    if (!_sealLedgerRepository.isConfigured || userId.trim().isEmpty) {
      return const CloudVaultSyncOutcome.skipped();
    }
    if (!await rawSourceFile.exists()) {
      return const CloudVaultSyncOutcome.skipped();
    }

    final fileSize = await rawSourceFile.length();
    if (fileSize > SupabaseVaultService.maxUploadBytes) {
      return CloudVaultSyncOutcome(
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
          vault: DefaultVaultEncryptionHandler(),
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

      return CloudVaultSyncOutcome(
        uploaded: true,
        storagePath: storagePath,
        packageId: packageId,
      );
    } on QuotaExceededException {
      return const CloudVaultSyncOutcome(
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
