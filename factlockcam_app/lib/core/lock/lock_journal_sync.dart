import '../journal/journal_repository.dart';
import '../journal/transaction_status.dart';
import 'isolate_lock_coordinator.dart';

/// Mirrors journal `prepared` rows into UI lock state after boot or crash.
void syncLocksFromPreparedJournal({
  required JournalRepository journal,
  required IsolateLockCoordinator coordinator,
}) {
  if (!journal.isAvailable) {
    return;
  }
  for (final entry in journal.listByStatus(TransactionStatus.prepared)) {
    coordinator.lock(entry.assetFingerprint);
  }
}
