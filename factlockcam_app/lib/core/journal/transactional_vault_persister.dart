import 'dart:typed_data';

import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../data/services/local_vault_storage.dart';
import 'journal_repository.dart';

/// Prepare → write staging files → atomic rename → commit journal + archive row.
class TransactionalVaultPersister {
  TransactionalVaultPersister({
    required JournalRepository journal,
    required LocalVaultStorage storage,
    required VaultDatabase database,
  }) : _journal = journal,
       _storage = storage,
       _database = database;

  final JournalRepository _journal;
  final LocalVaultStorage _storage;
  final VaultDatabase _database;

  Future<void> persistSealedAsset({
    required String assetFingerprint,
    required Uint8List encryptedBytes,
    required Uint8List thumbnailBytes,
    required int rawByteLength,
    String? mimeType,
    required bool pendingSync,
    String? chainTxHash,
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
      );
      return;
    }

    await _journal.open();

    final paths = await _storage.resolveTransactionalPaths(assetFingerprint);
    final transactionId =
        '${assetFingerprint}_${DateTime.now().microsecondsSinceEpoch}';

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
      );
      await _storage.writeBytesToPath(
        paths.thumbnailStagingPath,
        thumbnailBytes,
      );

      await _storage.commitStagedFile(
        stagingPath: paths.encryptedStagingPath,
        finalPath: paths.encryptedFinalPath,
      );
      await _storage.commitStagedFile(
        stagingPath: paths.thumbnailStagingPath,
        finalPath: paths.thumbnailFinalPath,
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
        ),
      );
    } catch (error) {
      await _storage.purgePaths([
        paths.encryptedStagingPath,
        paths.thumbnailStagingPath,
        paths.encryptedFinalPath,
        paths.thumbnailFinalPath,
      ]);
      _journal.markRolledBack(transactionId);
      _journal.removeManifest(assetFingerprint);
      rethrow;
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
