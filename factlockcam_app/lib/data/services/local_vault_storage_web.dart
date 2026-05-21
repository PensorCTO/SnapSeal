import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../models/archive_item.dart';

final localVaultStorageProvider = Provider<LocalVaultStorage>(
  (ref) => getIt<LocalVaultStorage>(),
);

class LocalVaultStorage {
  Future<ArchiveItem> resolveArchivePaths(ArchiveItem item) async => item;

  Future<String> writeEncryptedOriginal({
    required String assetFingerprint,
    required Uint8List bytes,
  }) async {
    throw UnsupportedError('Local vault storage is mobile-only.');
  }

  Future<String> writeThumbnail({
    required String assetFingerprint,
    required Uint8List bytes,
  }) async {
    throw UnsupportedError('Local vault storage is mobile-only.');
  }

  Future<Uint8List> readEncryptedOriginal(String path) async {
    throw UnsupportedError('Local vault storage is mobile-only.');
  }

  Future<void> deleteAssetFiles({
    required String encryptedPath,
    required String thumbnailPath,
  }) async {}

  Future<void> deleteAll() async {}
}
