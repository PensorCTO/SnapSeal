import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/archive/domain/archive_media_extension.dart';
import '../../core/di/locator.dart';
import '../../core/legal/disclaimers.dart';
import '../../data/models/archive_item.dart';
import '../../data/models/sealed_asset.dart';
import '../../data/supabase/seal_ledger_repository.dart';

final proofBundleExportServiceProvider = Provider<ProofBundleExportService>(
  (ref) => getIt<ProofBundleExportService>(),
);

/// Packages verified asset bytes, SHA-256 manifest, and anchoring metadata
/// into a zip written under the OS cache/temporary directory for safe sharing.
class ProofBundleExportService {
  ProofBundleExportService({SealLedgerRepository? sealLedgerRepository})
      : _sealLedgerRepository =
            sealLedgerRepository ?? getIt<SealLedgerRepository>();

  final SealLedgerRepository _sealLedgerRepository;

  Future<File> writeBundleToCache({
    required ArchiveItem item,
    required SealedAsset sealed,
    String? courierUrl,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Proof bundle export is unavailable on web.');
    }

    final chainTxHash = await _resolveChainTxHash(item);
    final extension = archiveMediaExtensionForMime(item.mimeType);
    final assetFileName = 'asset$extension';

    final manifest = <String, Object?>{
      'format': 'factlockcam-proof-bundle/v1',
      'assetFingerprint': item.assetFingerprint,
      'sha256': item.assetFingerprint,
      'byteLength': sealed.bytes.length,
      'mimeType': item.mimeType,
      'capturedAtUtc': item.createdAt.toUtc().toIso8601String(),
      'title': item.title,
      'description': item.description,
      'chainTxHash': chainTxHash,
      'pendingNotarization': item.pendingSync,
      if (courierUrl != null && courierUrl.isNotEmpty) 'courierUrl': courierUrl,
      'legalDisclaimer': fre902EvidencePackagingDisclaimer.trim(),
    };

    final manifestJson = utf8.encode(jsonEncode(manifest));
    final readmeBytes = utf8.encode(_readme);

    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'manifest.json',
          manifestJson.length,
          manifestJson,
        ),
      )
      ..addFile(
        ArchiveFile(assetFileName, sealed.bytes.length, sealed.bytes),
      )
      ..addFile(
        ArchiveFile(
          'README.txt',
          readmeBytes.length,
          readmeBytes,
        ),
      );

    final encoded = ZipEncoder().encode(archive);
    if (encoded.isEmpty) {
      throw StateError('Failed to encode proof bundle.');
    }

    final cacheDir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final shortHash = item.assetFingerprint.length >= 8
        ? item.assetFingerprint.substring(0, 8)
        : item.assetFingerprint;
    final bundlePath = p.join(
      cacheDir.path,
      'factlockcam_proof_${shortHash}_$stamp.zip',
    );
    final bundleFile = File(bundlePath);
    await bundleFile.writeAsBytes(encoded, flush: true);
    return bundleFile;
  }

  Future<String?> _resolveChainTxHash(ArchiveItem item) async {
    final local = item.chainTxHash?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }
    if (!_sealLedgerRepository.isConfigured) {
      return null;
    }
    try {
      return await _sealLedgerRepository.fetchProofChainTxHash(
        item.assetFingerprint,
      );
    } catch (_) {
      return null;
    }
  }

  static const _readme = '''
FactLockCam Proof Bundle
========================

This archive contains:
- asset.* — verified plaintext media bytes
- manifest.json — SHA-256 fingerprint and anchoring metadata

Verify the SHA-256 digest of asset.* matches manifest.json "sha256".
See manifest.json "legalDisclaimer" for FRE 902 workflow framing.
''';
}
