import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/di/locator.dart';
import '../models/archive_item.dart';
import 'vault_transactional_paths.dart';

final localVaultStorageProvider = Provider<LocalVaultStorage>(
  (ref) => getIt<LocalVaultStorage>(),
);

class LocalVaultStorage {
  /// Paths persisted in SQLite are absolute. If the app container moves (reinstall,
  /// simulator reset), those paths break while files still live under the current
  /// canonical vault layout. Prefer existing files at stored paths; otherwise fall
  /// back to `{vault}/thumbnails/{fingerprint}.jpg` and `{vault}/originals/{fingerprint}.seal`.
  Future<ArchiveItem> resolveArchivePaths(ArchiveItem item) async {
    final canonicalThumb = await _canonicalThumbnailPath(item.assetFingerprint);
    final canonicalEnc = await _canonicalEncryptedPath(item.assetFingerprint);

    var thumbnailPath = item.thumbnailPath;
    if (!_pathExists(thumbnailPath) && _pathExists(canonicalThumb)) {
      thumbnailPath = canonicalThumb;
    }

    var encryptedPath = item.encryptedPath;
    if (!_pathExists(encryptedPath) && _pathExists(canonicalEnc)) {
      encryptedPath = canonicalEnc;
    }

    if (thumbnailPath == item.thumbnailPath &&
        encryptedPath == item.encryptedPath) {
      return item;
    }

    return ArchiveItem(
      assetFingerprint: item.assetFingerprint,
      encryptedPath: encryptedPath,
      thumbnailPath: thumbnailPath,
      byteLength: item.byteLength,
      createdAt: item.createdAt,
      pendingSync: item.pendingSync,
      mimeType: item.mimeType,
      title: item.title,
      description: item.description,
      syncAttemptCount: item.syncAttemptCount,
      lastSyncAttemptAt: item.lastSyncAttemptAt,
      nextRetryAt: item.nextRetryAt,
    );
  }

  Future<String> _canonicalThumbnailPath(String assetFingerprint) async {
    final vault = await _vaultDirectory;
    return p.join(vault.path, 'thumbnails', '$assetFingerprint.jpg');
  }

  Future<String> _canonicalEncryptedPath(String assetFingerprint) async {
    final vault = await _vaultDirectory;
    return p.join(vault.path, 'originals', '$assetFingerprint.seal');
  }

  bool _pathExists(String path) {
    try {
      return File(path).existsSync();
    } on FileSystemException {
      return false;
    }
  }

  Future<Directory> get _vaultDirectory async {
    final documents = await getApplicationDocumentsDirectory();
    const modernName = 'factlockcam_vault';
    const legacyName = 'snapseal_vault';
    final modern = Directory(p.join(documents.path, modernName));
    if (modern.existsSync()) {
      return modern;
    }
    final legacy = Directory(p.join(documents.path, legacyName));
    if (legacy.existsSync()) {
      await legacy.rename(modern.path);
      return modern;
    }
    await modern.create(recursive: true);
    return modern;
  }

  Future<VaultTransactionalPaths> resolveTransactionalPaths(
    String assetFingerprint,
  ) async {
    final encryptedFinal = await _canonicalEncryptedPath(assetFingerprint);
    final thumbnailFinal = await _canonicalThumbnailPath(assetFingerprint);
    return VaultTransactionalPaths(
      encryptedFinalPath: encryptedFinal,
      thumbnailFinalPath: thumbnailFinal,
      encryptedStagingPath: '$encryptedFinal.part',
      thumbnailStagingPath: '$thumbnailFinal.part',
    );
  }

  Future<void> writeBytesToPath(String path, Uint8List bytes) async {
    final file = File(path);
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }
    await Isolate.run(
      () => File(path).writeAsBytesSync(bytes, flush: true),
    );
  }

  /// Atomically promotes a staging file to its final vault path (same volume).
  Future<void> commitStagedFile({
    required String stagingPath,
    required String finalPath,
  }) async {
    await Isolate.run(() {
      final staging = File(stagingPath);
      if (!staging.existsSync()) {
        throw StateError('Staging file missing: $stagingPath');
      }
      final target = File(finalPath);
      if (target.existsSync()) {
        target.deleteSync();
      }
      staging.renameSync(finalPath);
    });
  }

  Future<void> purgePaths(List<String> paths) async {
    await Isolate.run(() {
      for (final path in paths) {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    });
  }

  Future<String> writeEncryptedOriginal({
    required String assetFingerprint,
    required Uint8List bytes,
  }) async {
    final vault = await _vaultDirectory;
    final originals = Directory(p.join(vault.path, 'originals'));
    if (!originals.existsSync()) {
      await originals.create(recursive: true);
    }

    final targetPath = p.join(originals.path, '$assetFingerprint.seal');
    await Isolate.run(
      () => File(targetPath).writeAsBytesSync(bytes, flush: true),
    );
    return targetPath;
  }

  Future<String> writeThumbnail({
    required String assetFingerprint,
    required Uint8List bytes,
  }) async {
    final vault = await _vaultDirectory;
    final thumbnails = Directory(p.join(vault.path, 'thumbnails'));
    if (!thumbnails.existsSync()) {
      await thumbnails.create(recursive: true);
    }

    final targetPath = p.join(thumbnails.path, '$assetFingerprint.jpg');
    await Isolate.run(
      () => File(targetPath).writeAsBytesSync(bytes, flush: true),
    );
    return targetPath;
  }

  Future<Uint8List> readEncryptedOriginal(String path) {
    return Isolate.run(() => File(path).readAsBytesSync());
  }

  Future<void> deleteAssetFiles({
    required String encryptedPath,
    required String thumbnailPath,
  }) async {
    await Isolate.run(() {
      final encrypted = File(encryptedPath);
      if (encrypted.existsSync()) {
        encrypted.deleteSync();
      }
      final thumbnail = File(thumbnailPath);
      if (thumbnail.existsSync()) {
        thumbnail.deleteSync();
      }
    });
  }

  Future<void> deleteAll() async {
    final documents = await getApplicationDocumentsDirectory();
    for (final name in ['factlockcam_vault', 'snapseal_vault']) {
      final vault = Directory(p.join(documents.path, name));
      if (vault.existsSync()) {
        await vault.delete(recursive: true);
      }
    }
  }
}
