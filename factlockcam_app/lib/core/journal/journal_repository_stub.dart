import 'journal_database_factory.dart';
import 'journal_entry.dart';
import 'transaction_status.dart';

/// Web stub: SQLite journal logging is mobile/desktop only.
class JournalRepository {
  JournalRepository(this._factory);

  final JournalDatabaseFactory _factory;

  bool get isAvailable => _factory.isAvailable;

  Future<void> open() => _factory.open();

  void dispose() => _factory.dispose();

  String readJournalMode() => _factory.readJournalMode();

  List<JournalEntry> listByStatus(TransactionStatus status) => const [];

  void prepare({
    required String transactionId,
    required String assetFingerprint,
    required String encryptedTargetPath,
    required String thumbnailTargetPath,
    required String encryptedStagingPath,
    required String thumbnailStagingPath,
  }) {}

  void commit({
    required String transactionId,
    required String assetFingerprint,
    required String encryptedPath,
    required String thumbnailPath,
    required int byteLength,
    String? mimeType,
  }) {}

  void markRolledBack(String transactionId) {}

  void removeManifest(String assetFingerprint) {}

  int? committedByteLength(String assetFingerprint) => null;

  void purgeAsset(String assetFingerprint) {}
}
