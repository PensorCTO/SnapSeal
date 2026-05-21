import '../models/archive_item.dart';
import 'local_vault_storage.dart';

/// Resolves local filesystem paths for sealed archive items.
///
/// Wraps [LocalVaultStorage.resolveArchivePaths] to ensure every local file
/// system read in [VaultService] passes through resolution immediately before
/// IO, surviving iOS sandbox rotations where absolute paths stored in SQLite
/// become stale after application container UUID changes.
class VaultPathResolver {
  VaultPathResolver(this._storage);

  final LocalVaultStorage _storage;

  Future<ArchiveItem> resolve(ArchiveItem item) =>
      _storage.resolveArchivePaths(item);
}
