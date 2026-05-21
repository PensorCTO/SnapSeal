import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/di/locator.dart';
import '../models/archive_item.dart';

final vaultDatabaseProvider = Provider<VaultDatabase>(
  (ref) => getIt<VaultDatabase>(),
);

/// Renames a legacy SnapSeal DB (and SQLite `-wal` / `-shm` / `-journal` peers)
/// so first launch after rebrand continues on the same file.
Future<void> _migrateLegacyVaultDatabaseIfNeeded(String documentsPath) async {
  const modernBaseName = 'factlockcam_vault.db';
  const legacyBaseName = 'snapseal_vault.db';
  final modernBase = p.join(documentsPath, modernBaseName);
  final legacyBase = p.join(documentsPath, legacyBaseName);

  if (File(modernBase).existsSync()) {
    return;
  }
  if (!File(legacyBase).existsSync()) {
    return;
  }
  const companions = ['', '-wal', '-shm', '-journal'];
  for (final companion in companions) {
    final from = File('$legacyBase$companion');
    if (from.existsSync()) {
      await from.rename('$modernBase$companion');
    }
  }
}

class VaultDatabase {
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final documents = await getApplicationDocumentsDirectory();
    await _migrateLegacyVaultDatabaseIfNeeded(documents.path);
    final databasePath = p.join(documents.path, 'factlockcam_vault.db');

    return _database = await openDatabase(
      databasePath,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE archive_items (
            asset_fingerprint TEXT PRIMARY KEY,
            encrypted_path TEXT NOT NULL,
            thumbnail_path TEXT NOT NULL,
            byte_length INTEGER NOT NULL,
            mime_type TEXT,
            created_at TEXT NOT NULL,
            pending_sync INTEGER NOT NULL DEFAULT 0,
            chain_tx_hash TEXT,
            title TEXT,
            description TEXT,
            sync_attempt_count INTEGER NOT NULL DEFAULT 0,
            last_sync_attempt_at TEXT,
            next_retry_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN pending_sync INTEGER NOT NULL DEFAULT 0
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN title TEXT
          ''');
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN description TEXT
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN sync_attempt_count INTEGER NOT NULL DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN last_sync_attempt_at TEXT
          ''');
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN next_retry_at TEXT
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            ALTER TABLE archive_items
            ADD COLUMN chain_tx_hash TEXT
          ''');
        }
      },
    );
  }

  Future<void> upsertArchiveItem(ArchiveItem item) async {
    final db = await _db;
    await db.insert(
      'archive_items',
      item.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ArchiveItem>> listArchiveItems() async {
    final db = await _db;
    final rows = await db.query('archive_items', orderBy: 'created_at DESC');
    return rows.map(ArchiveItem.fromDatabase).toList(growable: false);
  }

  /// Items still marked for remote sync (e.g. offline or recoverable API failure).
  Future<List<ArchiveItem>> listPendingArchiveItems() async {
    final db = await _db;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = await db.query(
      'archive_items',
      where:
          'pending_sync = ? AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: [1, nowIso],
      orderBy: 'created_at ASC',
    );
    return rows.map(ArchiveItem.fromDatabase).toList(growable: false);
  }

  Future<ArchiveItem?> findArchiveItem(String assetFingerprint) async {
    final db = await _db;
    final rows = await db.query(
      'archive_items',
      where: 'asset_fingerprint = ?',
      whereArgs: [assetFingerprint],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ArchiveItem.fromDatabase(rows.single);
  }

  Future<void> setPendingSync({
    required String assetFingerprint,
    required bool pendingSync,
  }) async {
    final db = await _db;
    await db.update(
      'archive_items',
      {'pending_sync': pendingSync ? 1 : 0},
      where: 'asset_fingerprint = ?',
      whereArgs: [assetFingerprint],
    );
  }

  Future<void> markSyncSucceeded({
    required String assetFingerprint,
    String? chainTxHash,
  }) async {
    final db = await _db;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final update = <String, Object?>{
      'pending_sync': 0,
      'sync_attempt_count': 0,
      'last_sync_attempt_at': nowIso,
      'next_retry_at': null,
    };
    if (chainTxHash != null && chainTxHash.trim().isNotEmpty) {
      update['chain_tx_hash'] = chainTxHash.trim();
    }
    await db.update(
      'archive_items',
      update,
      where: 'asset_fingerprint = ?',
      whereArgs: [assetFingerprint],
    );
  }

  Future<void> markSyncDeferred({
    required String assetFingerprint,
    required DateTime nextRetryAt,
  }) async {
    final db = await _db;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.rawUpdate(
      '''
      UPDATE archive_items
      SET pending_sync = 1,
          sync_attempt_count = COALESCE(sync_attempt_count, 0) + 1,
          last_sync_attempt_at = ?,
          next_retry_at = ?
      WHERE asset_fingerprint = ?
      ''',
      [nowIso, nextRetryAt.toUtc().toIso8601String(), assetFingerprint],
    );
  }

  Future<void> updateArchiveMetadata({
    required String assetFingerprint,
    required String? title,
    required String? description,
  }) async {
    final db = await _db;
    await db.update(
      'archive_items',
      {'title': title, 'description': description},
      where: 'asset_fingerprint = ?',
      whereArgs: [assetFingerprint],
    );
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('archive_items');
  }

  /// Deletes the archive row only (callers should remove files via storage).
  Future<int> deleteArchiveItem(String assetFingerprint) async {
    final db = await _db;
    return db.delete(
      'archive_items',
      where: 'asset_fingerprint = ?',
      whereArgs: [assetFingerprint],
    );
  }
}
