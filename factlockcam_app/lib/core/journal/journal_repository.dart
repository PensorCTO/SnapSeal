import 'package:sqlite3/sqlite3.dart';

import 'journal_database_factory.dart';
import 'journal_entry.dart';
import 'transaction_status.dart';

/// SQLite journal for prepare / commit / rollback of vault file mutations.
class JournalRepository {
  JournalRepository(this._factory);

  final JournalDatabaseFactory _factory;

  Database get _db => _factory.database;

  bool get isAvailable => _factory.isAvailable;

  Future<void> open() => _factory.open();

  void dispose() => _factory.dispose();

  String readJournalMode() => _factory.readJournalMode();

  List<JournalEntry> listByStatus(TransactionStatus status) {
    final rows = _db.select(
      '''
      SELECT *
      FROM journal_log
      WHERE transaction_status = ?
      ORDER BY updated_at ASC
      ''',
      [status.dbValue],
    );
    return rows
        .map(
          (row) => JournalEntry.fromRow({
            'id': row['id'],
            'asset_fingerprint': row['asset_fingerprint'],
            'encrypted_target_path': row['encrypted_target_path'],
            'thumbnail_target_path': row['thumbnail_target_path'],
            'encrypted_staging_path': row['encrypted_staging_path'],
            'thumbnail_staging_path': row['thumbnail_staging_path'],
            'transaction_status': row['transaction_status'],
            'updated_at': row['updated_at'],
          }),
        )
        .toList(growable: false);
  }

  /// Logs intent **before** any filesystem write (prepare phase).
  void prepare({
    required String transactionId,
    required String assetFingerprint,
    required String encryptedTargetPath,
    required String thumbnailTargetPath,
    required String encryptedStagingPath,
    required String thumbnailStagingPath,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute(
      '''
      INSERT INTO journal_log (
        id,
        asset_fingerprint,
        encrypted_target_path,
        thumbnail_target_path,
        encrypted_staging_path,
        thumbnail_staging_path,
        transaction_status,
        updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        transactionId,
        assetFingerprint,
        encryptedTargetPath,
        thumbnailTargetPath,
        encryptedStagingPath,
        thumbnailStagingPath,
        TransactionStatus.prepared.dbValue,
        now,
      ],
    );
  }

  /// Finalizes journal + manifest after atomic renames succeed.
  void commit({
    required String transactionId,
    required String assetFingerprint,
    required String encryptedPath,
    required String thumbnailPath,
    required int byteLength,
    String? mimeType,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute('BEGIN IMMEDIATE;');
    try {
      _db.execute(
        '''
        UPDATE journal_log
        SET transaction_status = ?, updated_at = ?
        WHERE id = ?
        ''',
        [TransactionStatus.committed.dbValue, now, transactionId],
      );
      _db.execute(
        '''
        INSERT INTO asset_manifest (
          asset_fingerprint,
          encrypted_path,
          thumbnail_path,
          byte_length,
          mime_type,
          committed_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(asset_fingerprint) DO UPDATE SET
          encrypted_path = excluded.encrypted_path,
          thumbnail_path = excluded.thumbnail_path,
          byte_length = excluded.byte_length,
          mime_type = excluded.mime_type,
          committed_at = excluded.committed_at
        ''',
        [
          assetFingerprint,
          encryptedPath,
          thumbnailPath,
          byteLength,
          mimeType,
          now,
        ],
      );
      _db.execute('COMMIT;');
    } catch (e) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  void markRolledBack(String transactionId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _db.execute(
      '''
      UPDATE journal_log
      SET transaction_status = ?, updated_at = ?
      WHERE id = ?
      ''',
      [TransactionStatus.rolledBack.dbValue, now, transactionId],
    );
  }

  void removeManifest(String assetFingerprint) {
    _db.execute(
      'DELETE FROM asset_manifest WHERE asset_fingerprint = ?',
      [assetFingerprint],
    );
  }
}
