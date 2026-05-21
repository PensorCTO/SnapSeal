import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/vault_database.dart';
import '../../../../data/services/local_vault_storage.dart';

/// Off-thread thumbnail cache keyed by [assetFingerprint].
///
/// Reads the JPEG thumbnail file from disk inside [Isolate.run] and returns
/// the decoded bytes for use with `Image.memory()`. Web returns empty bytes
/// (the archive thumbnail fallback icon is used instead).
///
/// Cached for the lifetime of the provider scope so repeated rebuilds
/// (e.g. during scrolling) do not re-decode the same thumbnail.
final thumbnailCacheProvider =
    FutureProvider.family<Uint8List, String>((ref, assetFingerprint) async {
  if (kIsWeb) {
    return Uint8List(0);
  }

  final db = ref.read(vaultDatabaseProvider);
  final rawItem = await db.findArchiveItem(assetFingerprint);
  if (rawItem == null) {
    return Uint8List(0);
  }

  final storage = ref.read(localVaultStorageProvider);
  final item = await storage.resolveArchivePaths(rawItem);
  if (!_thumbnailFileExists(item.thumbnailPath)) {
    return Uint8List(0);
  }

  final thumbnailPath = item.thumbnailPath;
  return Isolate.run(() {
    return File(thumbnailPath).readAsBytesSync();
  });
});

bool _thumbnailFileExists(String path) {
  try {
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  } on FileSystemException {
    return false;
  }
}
