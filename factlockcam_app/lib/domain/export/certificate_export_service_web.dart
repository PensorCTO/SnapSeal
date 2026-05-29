import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../data/models/archive_item.dart';
import '../../data/supabase/seal_ledger_repository.dart';
import 'certificate_pdf_cache_file.dart';

final certificateExportServiceProvider = Provider<CertificateExportService>(
  (ref) => getIt<CertificateExportService>(),
);

/// Web stub — certificate PDF export is mobile-only (Send Proof share sheet).
class CertificateExportService {
  CertificateExportService({SealLedgerRepository? sealLedgerRepository});

  Future<String> buildCertificateDraft(ArchiveItem item) async {
    throw UnsupportedError('Certificate export is unavailable on web.');
  }

  Future<Uint8List> generateCertificatePdf(
    ArchiveItem item, {
    String? titleOverride,
    String? descriptionOverride,
    String? thumbnailPath,
  }) async {
    throw UnsupportedError('Certificate PDF export is unavailable on web.');
  }

  Future<CertificatePdfCacheFile> writeCertificatePdfToCache(
    ArchiveItem item, {
    String? titleOverride,
    String? descriptionOverride,
    String? thumbnailPath,
  }) async {
    throw UnsupportedError('Certificate PDF export is unavailable on web.');
  }
}
