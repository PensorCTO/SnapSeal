import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/archive/domain/archive_media_extension.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';

Future<void> shareDecryptedArchiveMedia({
  required ArchiveItem item,
  required SealedAsset sealed,
}) async {
  final cacheDir = await getTemporaryDirectory();
  final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
  final shortHash = item.assetFingerprint.length >= 8
      ? item.assetFingerprint.substring(0, 8)
      : item.assetFingerprint;
  final extension = archiveMediaExtensionForMime(item.mimeType);
  final filePath = p.join(
    cacheDir.path,
    'factlockcam_media_${shortHash}_$stamp$extension',
  );
  final file = File(filePath);
  await file.writeAsBytes(sealed.bytes, flush: true);

  final mime = item.mimeType?.trim();
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType: mime != null && mime.isNotEmpty ? mime : null,
          name: 'factlockcam$extension',
        ),
      ],
      text:
          'Unencrypted copy from your FactLockCam archive. '
          'Store only where you trust this device.',
    ),
  );
}
