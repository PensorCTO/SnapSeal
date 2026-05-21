import 'package:flutter/foundation.dart';

import 'boot_recovery_service.dart';
import 'journal_database_factory.dart';
import 'journal_repository.dart';

/// Executes the Sprint 2 recovery loop before Flutter UI initializes.
Future<void> runBootRecoveryBeforeUi() async {
  final factory = JournalDatabaseFactory();
  final journal = JournalRepository(factory);
  try {
    await BootRecoveryService(journal).run();
  } catch (e, stack) {
    // Structural fallback: never crash launch on recovery failure.
    debugPrint('Critical Recovery Failure: $e\n$stack');
  } finally {
    journal.dispose();
  }
}
