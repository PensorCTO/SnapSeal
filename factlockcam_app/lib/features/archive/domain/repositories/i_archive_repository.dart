import '../../../../data/models/archive_item.dart';
import '../models/archive_asset.dart';

abstract class IArchiveRepository {
  Stream<List<ArchiveAsset>> watchDigitalArchiveManifest();

  ArchiveAsset mapArchiveItem(
    ArchiveItem item, {
    required String? activeWalletAddress,
  });

  Future<void> rehydratePlaceholderAsset({
    required String assetHash,
    required List<int> backupBinaryPayload,
  });
}
