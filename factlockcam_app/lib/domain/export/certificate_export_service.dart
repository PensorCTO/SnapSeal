import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/legal/disclaimers.dart';
import '../../data/models/archive_item.dart';
import '../../data/supabase/seal_ledger_repository.dart';

final certificateExportServiceProvider = Provider<CertificateExportService>(
  (ref) => getIt<CertificateExportService>(),
);

class CertificateExportService {
  CertificateExportService({SealLedgerRepository? sealLedgerRepository})
      : _sealLedgerRepository =
            sealLedgerRepository ?? getIt<SealLedgerRepository>();

  final SealLedgerRepository _sealLedgerRepository;
  final Map<String, String?> _chainTxHashCache = <String, String?>{};

  /// Draft payload until PDF/printing is wired in Phase 2 follow-ups.
  Future<String> buildCertificateDraft(ArchiveItem item) async {
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Untitled evidence';
    final description = item.description?.trim().isNotEmpty == true
        ? item.description!.trim()
        : 'No description provided.';

    final chainTxHash = await _resolveChainTxHash(item);

    final ledgerTxLine = chainTxHash != null && chainTxHash.isNotEmpty
        ? 'Ledger Transaction Hash: $chainTxHash'
        : 'Ledger Transaction Hash: Pending notarization';

    return '''
FactLockCam Certificate Draft

Title: $title
Asset Fingerprint: ${item.assetFingerprint}
$ledgerTxLine
Captured At (UTC): ${item.createdAt.toUtc().toIso8601String()}
Description: $description

$fre902EvidencePackagingDisclaimer
''';
  }

  Future<String?> _resolveChainTxHash(ArchiveItem item) async {
    final local = item.chainTxHash?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }

    final cached = _chainTxHashCache[item.assetFingerprint];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (_chainTxHashCache.containsKey(item.assetFingerprint)) {
      return null;
    }

    if (!_sealLedgerRepository.isConfigured) {
      _chainTxHashCache[item.assetFingerprint] = null;
      return null;
    }

    try {
      final remote = await _sealLedgerRepository.fetchProofChainTxHash(
        item.assetFingerprint,
      );
      _chainTxHashCache[item.assetFingerprint] = remote;
      return remote;
    } catch (_) {
      _chainTxHashCache[item.assetFingerprint] = null;
      return null;
    }
  }
}
