import 'transaction_status.dart';

/// Row from [journal_log] used by boot recovery and transactional persist.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.assetFingerprint,
    required this.encryptedTargetPath,
    required this.thumbnailTargetPath,
    required this.encryptedStagingPath,
    required this.thumbnailStagingPath,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String assetFingerprint;
  final String encryptedTargetPath;
  final String thumbnailTargetPath;
  final String encryptedStagingPath;
  final String thumbnailStagingPath;
  final TransactionStatus status;
  final int updatedAt;

  factory JournalEntry.fromRow(Map<String, Object?> row) {
    return JournalEntry(
      id: row['id']! as String,
      assetFingerprint: row['asset_fingerprint']! as String,
      encryptedTargetPath: row['encrypted_target_path']! as String,
      thumbnailTargetPath: row['thumbnail_target_path']! as String,
      encryptedStagingPath: row['encrypted_staging_path']! as String,
      thumbnailStagingPath: row['thumbnail_staging_path']! as String,
      status: TransactionStatus.fromDb(row['transaction_status']! as String),
      updatedAt: row['updated_at']! as int,
    );
  }
}
