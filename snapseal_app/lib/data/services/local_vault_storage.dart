import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final localVaultStorageProvider = Provider<LocalVaultStorage>(
  (ref) => LocalVaultStorage(),
);

class LocalVaultStorage {
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
    await Isolate.run(() => File(targetPath).writeAsBytesSync(bytes, flush: true));
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
    await Isolate.run(() => File(targetPath).writeAsBytesSync(bytes, flush: true));
    return targetPath;
  }

  Future<Uint8List> readEncryptedOriginal(String path) {
    return Isolate.run(() => File(path).readAsBytesSync());
  }

  Future<void> deleteAll() async {
    final vault = await _vaultDirectory;
    if (vault.existsSync()) {
      await vault.delete(recursive: true);
    }
  }
}
