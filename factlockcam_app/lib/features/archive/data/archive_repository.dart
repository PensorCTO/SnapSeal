import 'dart:async';
import 'dart:io';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/locator.dart';
import '../../../data/local/vault_database.dart';
import '../../../data/models/archive_item.dart';
import '../../../data/services/local_vault_storage.dart';
import '../../identity/presentation/providers/current_profile_provider.dart';
import '../domain/models/archive_asset.dart';
import '../domain/repositories/i_archive_repository.dart';

final archiveRepositoryProvider = Provider<IArchiveRepository>(
  (ref) => getIt<ArchiveRepository>(),
);

class ArchiveRepository implements IArchiveRepository {
  ArchiveRepository({
    required VaultDatabase database,
    required LocalVaultStorage storage,
  })  : _database = database,
        _storage = storage;

  final VaultDatabase _database;
  final LocalVaultStorage _storage;
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  void notifyManifestChanged() {
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }

  @override
  Stream<List<ArchiveAsset>> watchDigitalArchiveManifest() async* {
    yield await _loadManifest(activeWalletAddress: null);
    await for (final _ in _refreshController.stream) {
      yield await _loadManifest(activeWalletAddress: null);
    }
  }

  Future<List<ArchiveAsset>> loadManifest({String? activeWalletAddress}) {
    return _loadManifest(activeWalletAddress: activeWalletAddress);
  }

  Future<List<ArchiveAsset>> _loadManifest({
    required String? activeWalletAddress,
  }) async {
    final items = await _database.listArchiveItems();
    return items
        .map(
          (item) => _mapItem(
            item,
            activeWalletAddress: activeWalletAddress,
          ),
        )
        .toList(growable: false);
  }

  @override
  ArchiveAsset mapArchiveItem(
    ArchiveItem item, {
    required String? activeWalletAddress,
  }) {
    return _mapItem(item, activeWalletAddress: activeWalletAddress);
  }

  ArchiveAsset _mapItem(
    ArchiveItem item, {
    required String? activeWalletAddress,
  }) {
    final wallet = item.walletAddress?.trim();
    final active = activeWalletAddress?.trim();
    final isLegacy = wallet != null &&
        wallet.isNotEmpty &&
        active != null &&
        active.isNotEmpty &&
        wallet.toLowerCase() != active.toLowerCase();
    final localAvailable =
        item.isLocallyAvailable && _encryptedFileExists(item.encryptedPath);

    return ArchiveAsset(
      assetHash: item.assetFingerprint,
      walletAddress: wallet,
      isLocallyAvailable: localAvailable,
      isLegacyPlaceholder: isLegacy,
      mimeType: item.mimeType,
      createdAt: item.createdAt,
      pendingSync: item.pendingSync,
    );
  }

  bool _encryptedFileExists(String encryptedPath) {
    if (encryptedPath.trim().isEmpty) {
      return false;
    }
    return File(encryptedPath).existsSync();
  }

  @override
  Future<void> rehydratePlaceholderAsset({
    required String assetHash,
    required List<int> backupBinaryPayload,
  }) async {
    final item = await _database.findArchiveItem(assetHash);
    if (item == null) {
      throw StateError('No archive row exists for $assetHash.');
    }

    final encryptedPath = await _storage.writeEncryptedOriginal(
      assetFingerprint: assetHash,
      bytes: Uint8List.fromList(backupBinaryPayload),
    );

    await _database.upsertArchiveItem(
      item.copyWith(
        encryptedPath: encryptedPath,
        isLocallyAvailable: true,
        byteLength: backupBinaryPayload.length,
      ),
    );
    notifyManifestChanged();
  }
}

/// Maps dashboard [ArchiveItem]s with the active profile wallet for UI state.
final archiveAssetManifestProvider = FutureProvider<List<ArchiveAsset>>((
  ref,
) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final repository = ref.watch(archiveRepositoryProvider);
  final items = await ref.watch(vaultDatabaseProvider).listArchiveItems();
  return items
      .map(
        (item) => repository.mapArchiveItem(
          item,
          activeWalletAddress: profile.activeWalletAddress,
        ),
      )
      .toList(growable: false);
});
