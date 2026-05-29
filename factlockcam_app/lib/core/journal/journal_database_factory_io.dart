import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// Opens the embedded journal database with WAL + NORMAL synchronous mode.
class JournalDatabaseFactory {
  JournalDatabaseFactory({String? embeddedPath}) : _embeddedPath = embeddedPath;

  final String? _embeddedPath;
  Database? _database;
  Completer<void>? _opening;

  Database get database {
    final db = _database;
    if (db == null) {
      throw StateError('JournalDatabaseFactory.open() was not called.');
    }
    return db;
  }

  bool get isAvailable => true;

  Future<void> open() async {
    if (_database != null) {
      return;
    }

    final inFlight = _opening;
    if (inFlight != null) {
      return inFlight.future;
    }

    final opening = Completer<void>();
    _opening = opening;
    try {
      await _openJournalDatabase();
      opening.complete();
    } catch (error, stackTrace) {
      opening.completeError(error, stackTrace);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<void> _openJournalDatabase() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final embeddedPath = _embeddedPath ??
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'factlockcam_journal.db',
        );
    final db = sqlite3.open(embeddedPath);

    db.execute('PRAGMA journal_mode = WAL;');
    db.execute('PRAGMA synchronous = NORMAL;');
    db.execute('PRAGMA foreign_keys = ON;');
    db.execute('PRAGMA busy_timeout = 5000;');

    _applyBaselineSchema(db);
    _database = db;
  }

  void dispose() {
    _database?.dispose();
    _database = null;
  }

  /// Runtime confirmation for Sprint 2 DoD (journal_mode must be `wal`).
  String readJournalMode() {
    final row = database.select('PRAGMA journal_mode;').first;
    return row.columnAt(0) as String;
  }

  static void _applyBaselineSchema(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS journal_log (
        id TEXT PRIMARY KEY,
        asset_fingerprint TEXT NOT NULL,
        encrypted_target_path TEXT NOT NULL,
        thumbnail_target_path TEXT NOT NULL,
        encrypted_staging_path TEXT NOT NULL,
        thumbnail_staging_path TEXT NOT NULL,
        transaction_status TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    db.execute('''
      CREATE INDEX IF NOT EXISTS idx_journal_log_status
      ON journal_log (transaction_status);
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS asset_manifest (
        asset_fingerprint TEXT PRIMARY KEY,
        encrypted_path TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        byte_length INTEGER NOT NULL,
        mime_type TEXT,
        committed_at INTEGER NOT NULL
      );
    ''');
  }
}
