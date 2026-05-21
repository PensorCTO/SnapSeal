import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/legal/disclaimers.dart';
import '../../data/models/archive_item.dart';

final certificateExportServiceProvider = Provider<CertificateExportService>(
  (ref) => getIt<CertificateExportService>(),
);

class CertificateExportService {
  /// Draft payload until PDF/printing is wired in Phase 2 follow-ups.
  String buildCertificateDraft(ArchiveItem item) {
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Untitled evidence';
    final description = item.description?.trim().isNotEmpty == true
        ? item.description!.trim()
        : 'No description provided.';

    return '''
FactLockCam Certificate Draft

Title: $title
Asset Fingerprint: ${item.assetFingerprint}
Captured At (UTC): ${item.createdAt.toUtc().toIso8601String()}
Description: $description

$fre902EvidencePackagingDisclaimer
''';
  }
}
