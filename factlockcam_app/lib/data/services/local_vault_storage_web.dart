import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/lock/isolate_lock_coordinator.dart';
import '../models/archive_item.dart';
import 'vault_transactional_paths.dart';

final localVaultStorageProvider = Provider<LocalVaultStorage>(
  (ref) => getIt<LocalVaultStorage>(),
);

class LocalVaultStorage {
  LocalVaultStorage({IsolateLockCoordinator? lockCoordinator});

  Future<ArchiveItem> resolveArchivePaths(ArchiveItem item) async => item;

  Future<VaultTransactionalPaths> resolveTransactionalPaths(
    String assetFingerprint,
  ) async {
    throw UnsupportedError('Transactional vault paths are mobile-only.');
  }

  Future<void> writeBytesToPath(
    String path,
    Uint8List bytes, {
    required String assetFingerprint,
  }) async {
    throw UnsupportedError('Transactional vault writes are mobile-only.');
  }

  Future<void> commitStagedFile({
    required String stagingPath,
    required String finalPath,
    required String assetFingerprint,
  }) async {
    throw UnsupportedError('Transactional vault commit is mobile-only.');
  }

  Future<void> purgePaths(List<String> paths) async {}

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

  Future<Uint8List> readEncryptedOriginal(
    String path, {
    String? assetFingerprint,
  }) async {
    throw UnsupportedError('Local vault storage is mobile-only.');
  }

  Future<void> deleteAssetFiles({
    required String encryptedPath,
    required String thumbnailPath,
  }) async {}

  Future<void> deleteAll() async {}
}
