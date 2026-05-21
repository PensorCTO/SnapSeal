import 'dart:io';

import 'package:flutter/foundation.dart';

import 'journal_entry.dart';
import 'journal_repository.dart';
import 'transaction_status.dart';

/// Scans [journal_log] for dangling `prepared` rows and rolls back orphaned files.
class BootRecoveryService {
  BootRecoveryService(this._journal);

  final JournalRepository _journal;

  /// Silent recovery intended to run from [main] before [runApp].
  Future<BootRecoveryReport> run() async {
    if (!_journal.isAvailable) {
      return const BootRecoveryReport(skipped: true);
    }

    await _journal.open();
    final prepared = _journal.listByStatus(TransactionStatus.prepared);
    var rolledBack = 0;

    for (final entry in prepared) {
      await _purgeOrphanedFiles(entry);
      _journal.markRolledBack(entry.id);
      _journal.removeManifest(entry.assetFingerprint);
      rolledBack++;
    }

    if (rolledBack > 0 && kDebugMode) {
      debugPrint(
        'BootRecovery: rolled back $rolledBack interrupted transaction(s).',
      );
    }

    return BootRecoveryReport(rolledBackCount: rolledBack);
  }

  Future<void> _purgeOrphanedFiles(JournalEntry entry) async {
    for (final path in [
      entry.encryptedStagingPath,
      entry.thumbnailStagingPath,
      entry.encryptedTargetPath,
      entry.thumbnailTargetPath,
    ]) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}

class BootRecoveryReport {
  const BootRecoveryReport({this.rolledBackCount = 0, this.skipped = false});

  final int rolledBackCount;
  final bool skipped;
}
