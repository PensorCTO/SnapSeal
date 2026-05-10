import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/di/locator.dart';
import '../models/archive_item.dart';

final localVaultStorageProvider = Provider<LocalVaultStorage>(
  (ref) => getIt<LocalVaultStorage>(),
);

class LocalVaultStorage {
  /// Paths persisted in SQLite are absolute. If the app container moves (reinstall,
  /// simulator reset), those paths break while files still live under the current
  /// canonical vault layout. Prefer existing files at stored paths; otherwise fall
  /// back to `{vault}/thumbnails/{fingerprint}.jpg` and `{vault}/originals/{fingerprint}.seal`.
  Future<ArchiveItem> resolveArchivePaths(ArchiveItem item) async {
    final canonicalThumb =
        await _canonicalThumbnailPath(item.assetFingerprint);
    final canonicalEnc =
        await _canonicalEncryptedPath(item.assetFingerprint);

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
    final directory = Directory(p.join(documents.path, 'snapseal_vault'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
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
    final vault = await _vaultDirectory;
    if (vault.existsSync()) {
      await vault.delete(recursive: true);
    }
  }
}
