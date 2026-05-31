import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';

Future<void> shareDecryptedArchiveMedia({
  required ArchiveItem item,
  required SealedAsset sealed,
}) {
  throw UnsupportedError(
    'Download Media is only available on iOS and Android.',
  );
}
