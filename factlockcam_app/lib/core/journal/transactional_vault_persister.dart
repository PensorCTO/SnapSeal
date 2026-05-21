import 'dart:typed_data';

import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../data/services/local_vault_storage.dart';
import '../lock/isolate_lock_coordinator.dart';
import 'journal_repository.dart';

/// Prepare → write staging files → atomic rename → commit journal + archive row.
class TransactionalVaultPersister {
  TransactionalVaultPersister({
    required JournalRepository journal,
    required LocalVaultStorage storage,
    required VaultDatabase database,
    IsolateLockCoordinator? lockCoordinator,
  }) : _journal = journal,
       _storage = storage,
       _database = database,
       _lockCoordinator = lockCoordinator;

  final JournalRepository _journal;
  final LocalVaultStorage _storage;
  final VaultDatabase _database;
  final IsolateLockCoordinator? _lockCoordinator;

  Future<void> persistSealedAsset({
    required String assetFingerprint,
    required Uint8List encryptedBytes,
    required Uint8List thumbnailBytes,
    required int rawByteLength,
    String? mimeType,
    required bool pendingSync,
    String? chainTxHash,
    String? walletAddress,
  }) async {
    if (!_journal.isAvailable) {
      await _legacyPersist(
        assetFingerprint: assetFingerprint,
        encryptedBytes: encryptedBytes,
        thumbnailBytes: thumbnailBytes,
        rawByteLength: rawByteLength,
        mimeType: mimeType,
        pendingSync: pendingSync,
        chainTxHash: chainTxHash,
        walletAddress: walletAddress,
      );
      return;
    }

    await _journal.open();

    final paths = await _storage.resolveTransactionalPaths(assetFingerprint);
    final transactionId =
        '${assetFingerprint}_${DateTime.now().microsecondsSinceEpoch}';

    _lockCoordinator?.lock(assetFingerprint);
    _journal.prepare(
      transactionId: transactionId,
      assetFingerprint: assetFingerprint,
      encryptedTargetPath: paths.encryptedFinalPath,
      thumbnailTargetPath: paths.thumbnailFinalPath,
      encryptedStagingPath: paths.encryptedStagingPath,
      thumbnailStagingPath: paths.thumbnailStagingPath,
    );

    try {
      await _storage.writeBytesToPath(
        paths.encryptedStagingPath,
        encryptedBytes,
        assetFingerprint: assetFingerprint,
      );
      await _storage.writeBytesToPath(
        paths.thumbnailStagingPath,
        thumbnailBytes,
        assetFingerprint: assetFingerprint,
      );

      await _storage.commitStagedFile(
        stagingPath: paths.encryptedStagingPath,
        finalPath: paths.encryptedFinalPath,
        assetFingerprint: assetFingerprint,
      );
      await _storage.commitStagedFile(
        stagingPath: paths.thumbnailStagingPath,
        finalPath: paths.thumbnailFinalPath,
        assetFingerprint: assetFingerprint,
      );

      _journal.commit(
        transactionId: transactionId,
        assetFingerprint: assetFingerprint,
        encryptedPath: paths.encryptedFinalPath,
        thumbnailPath: paths.thumbnailFinalPath,
        byteLength: rawByteLength,
        mimeType: mimeType,
      );

      await _database.upsertArchiveItem(
        ArchiveItem(
          assetFingerprint: assetFingerprint,
          encryptedPath: paths.encryptedFinalPath,
          thumbnailPath: paths.thumbnailFinalPath,
          byteLength: rawByteLength,
          mimeType: mimeType,
          createdAt: DateTime.now().toUtc(),
          pendingSync: pendingSync,
          title: null,
          description: null,
          syncAttemptCount: 0,
          lastSyncAttemptAt: null,
          nextRetryAt: null,
          chainTxHash: chainTxHash,
          walletAddress: walletAddress,
        ),
      );
    } catch (error) {
      await _storage.purgePaths(paths.pathsForPurge);
      _journal.markRolledBack(transactionId);
      _journal.removeManifest(assetFingerprint);
      rethrow;
    } finally {
      _lockCoordinator?.unlock(assetFingerprint);
    }
  }

  Future<void> _legacyPersist({
    required String assetFingerprint,
    required Uint8List encryptedBytes,
    required Uint8List thumbnailBytes,
    required int rawByteLength,
    String? mimeType,
    required bool pendingSync,
    String? chainTxHash,
    String? walletAddress,
  }) async {
    final encryptedPath = await _storage.writeEncryptedOriginal(
      assetFingerprint: assetFingerprint,
      bytes: encryptedBytes,
    );
    final thumbnailPath = await _storage.writeThumbnail(
      assetFingerprint: assetFingerprint,
      bytes: thumbnailBytes,
    );

    try {
      await _database.upsertArchiveItem(
        ArchiveItem(
          assetFingerprint: assetFingerprint,
          encryptedPath: encryptedPath,
          thumbnailPath: thumbnailPath,
          byteLength: rawByteLength,
          mimeType: mimeType,
          createdAt: DateTime.now().toUtc(),
          pendingSync: pendingSync,
          title: null,
          description: null,
          syncAttemptCount: 0,
          lastSyncAttemptAt: null,
          nextRetryAt: null,
          chainTxHash: chainTxHash,
          walletAddress: walletAddress,
        ),
      );
    } catch (_) {
      await _storage.deleteAssetFiles(
        encryptedPath: encryptedPath,
        thumbnailPath: thumbnailPath,
      );
      rethrow;
    }
  }
}
