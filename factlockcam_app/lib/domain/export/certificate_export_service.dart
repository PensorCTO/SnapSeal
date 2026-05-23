import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/di/locator.dart';
import '../../core/legal/disclaimers.dart';
import '../../data/models/archive_item.dart';
import '../../data/supabase/seal_ledger_repository.dart';

final certificateExportServiceProvider = Provider<CertificateExportService>(
  (ref) => getIt<CertificateExportService>(),
);

/// Immutable visual proof export (PDF) for Send Proof workflows.
class CertificateExportService {
  CertificateExportService({SealLedgerRepository? sealLedgerRepository})
      : _sealLedgerRepository =
            sealLedgerRepository ?? getIt<SealLedgerRepository>();

  final SealLedgerRepository _sealLedgerRepository;
  final Map<String, String?> _chainTxHashCache = <String, String?>{};

  /// Text draft retained for quick inspection in the archive UI.
  Future<String> buildCertificateDraft(ArchiveItem item) async {
    final title = _resolveTitle(item);
    final description = _resolveDescription(item);
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

  /// Generates a certificate PDF off the UI thread when [thumbnailPath] is set.
  Future<Uint8List> generateCertificatePdf(
    ArchiveItem item, {
    String? titleOverride,
    String? descriptionOverride,
    String? thumbnailPath,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Certificate PDF export is unavailable on web.');
    }

    final chainTxHash = await _resolveChainTxHash(item);
    final input = _CertificatePdfInput(
      title: titleOverride?.trim().isNotEmpty == true
          ? titleOverride!.trim()
          : _resolveTitle(item),
      description: descriptionOverride?.trim().isNotEmpty == true
          ? descriptionOverride!.trim()
          : _resolveDescription(item),
      assetFingerprint: item.assetFingerprint,
      chainTxHash: chainTxHash,
      capturedAtUtc: item.createdAt.toUtc().toIso8601String(),
      thumbnailPath: thumbnailPath,
    );

    return _buildCertificatePdf(input);
  }

  /// Writes a certificate PDF to the device temp folder for sharing.
  Future<File> writeCertificatePdfToCache(
    ArchiveItem item, {
    String? titleOverride,
    String? descriptionOverride,
    String? thumbnailPath,
  }) async {
    final bytes = await generateCertificatePdf(
      item,
      titleOverride: titleOverride,
      descriptionOverride: descriptionOverride,
      thumbnailPath: thumbnailPath,
    );
    final cacheDir = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final shortHash = item.assetFingerprint.length >= 8
        ? item.assetFingerprint.substring(0, 8)
        : item.assetFingerprint;
    final filePath = p.join(
      cacheDir.path,
      'factlockcam_certificate_${shortHash}_$stamp.pdf',
    );
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _resolveTitle(ArchiveItem item) {
    return item.title?.trim().isNotEmpty == true
        ? item.title!.trim()
        : 'Untitled evidence';
  }

  String _resolveDescription(ArchiveItem item) {
    return item.description?.trim().isNotEmpty == true
        ? item.description!.trim()
        : 'No description provided.';
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

class _CertificatePdfInput {
  const _CertificatePdfInput({
    required this.title,
    required this.description,
    required this.assetFingerprint,
    required this.capturedAtUtc,
    this.chainTxHash,
    this.thumbnailPath,
  });

  final String title;
  final String description;
  final String assetFingerprint;
  final String? chainTxHash;
  final String capturedAtUtc;
  final String? thumbnailPath;
}

Future<Uint8List> _buildCertificatePdf(_CertificatePdfInput input) async {
  final doc = pw.Document();
  final mono = pw.TextStyle(font: pw.Font.courier(), fontSize: 10);
  final monoBold = pw.TextStyle(
    font: pw.Font.courier(),
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: pw.Font.helveticaBold(),
    fontSize: 18,
    color: PdfColors.black,
  );

  pw.Widget? thumbnailWidget;
  final thumbPath = input.thumbnailPath?.trim();
  if (thumbPath != null && thumbPath.isNotEmpty) {
    try {
      final thumbFile = File(thumbPath);
      if (thumbFile.existsSync()) {
        final bytes = thumbFile.readAsBytesSync();
        final image = pw.MemoryImage(bytes);
        thumbnailWidget = pw.Container(
          height: 140,
          alignment: pw.Alignment.centerLeft,
          child: pw.Image(image, fit: pw.BoxFit.contain),
        );
      }
    } on FileSystemException {
      // Thumbnail optional — certificate still renders without it.
    }
  }

  final txHash = input.chainTxHash?.trim();
  final polygonLink = txHash != null && txHash.isNotEmpty
      ? 'https://polygonscan.com/tx/$txHash'
      : null;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => [
        pw.Text('FactLockCam Certificate', style: titleStyle),
        pw.SizedBox(height: 8),
        pw.Text(
          'Tamper-evident archive record',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        if (thumbnailWidget != null) ...[
          thumbnailWidget,
          pw.SizedBox(height: 16),
        ],
        pw.Text('Title', style: monoBold),
        pw.Text(input.title, style: mono),
        pw.SizedBox(height: 12),
        pw.Text('Description', style: monoBold),
        pw.Text(input.description, style: mono),
        pw.SizedBox(height: 12),
        pw.Text('Asset Hash (SHA-256)', style: monoBold),
        pw.Text(input.assetFingerprint, style: mono),
        pw.SizedBox(height: 12),
        pw.Text('Captured At (UTC)', style: monoBold),
        pw.Text(input.capturedAtUtc, style: mono),
        pw.SizedBox(height: 12),
        pw.Text('Ledger Transaction Hash', style: monoBold),
        pw.Text(
          txHash != null && txHash.isNotEmpty
              ? txHash
              : 'Pending notarization',
          style: mono,
        ),
        if (polygonLink != null) ...[
          pw.SizedBox(height: 8),
          pw.UrlLink(
            destination: polygonLink,
            child: pw.Text(
              polygonLink,
              style: pw.TextStyle(
                font: pw.Font.courier(),
                fontSize: 10,
                color: PdfColors.blue800,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 24),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(fre902EvidencePackagingDisclaimer, style: mono),
      ],
    ),
  );

  return Uint8List.fromList(await doc.save());
}
