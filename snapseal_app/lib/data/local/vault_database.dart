import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/di/locator.dart';
import '../models/archive_item.dart';

final vaultDatabaseProvider = Provider<VaultDatabase>((ref) => getIt<VaultDatabase>());

class VaultDatabase {
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final documents = await getApplicationDocumentsDirectory();
    final databasePath = p.join(documents.path, 'snapseal_vault.db');

    return _database = await openDatabase(
      databasePath,
      version: 3,
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
            title TEXT,
            description TEXT
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
    final rows = await db.query(
      'archive_items',
      where: 'pending_sync = ?',
      whereArgs: [1],
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
}
