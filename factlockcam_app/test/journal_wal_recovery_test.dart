import 'dart:io';
import 'dart:typed_data';

import 'package:factlockcam/core/journal/boot_recovery_service.dart';
import 'package:factlockcam/core/journal/journal_database_factory.dart';
import 'package:factlockcam/core/journal/journal_repository.dart';
import 'package:factlockcam/core/journal/transaction_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late JournalDatabaseFactory factory;
  late JournalRepository journal;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('factlockcam_journal_test_');
    factory = JournalDatabaseFactory(
      embeddedPath: '${tempDir.path}/journal.db',
    );
    journal = JournalRepository(factory);
    await journal.open();
  });

  tearDown(() async {
    journal.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('journal database initializes in WAL mode', () {
    expect(journal.readJournalMode().toLowerCase(), 'wal');
  });

  test('boot recovery rolls back prepared transaction and purges partial file',
      () async {
    final staging = File('${tempDir.path}/orphan.seal.part');
    final target = File('${tempDir.path}/orphan.seal');
    await staging.writeAsBytes(Uint8List.fromList([1, 2, 3]));

    journal.prepare(
      transactionId: 'txn-hard-kill',
      assetFingerprint: 'abc123',
      encryptedTargetPath: target.path,
      thumbnailTargetPath: '${tempDir.path}/orphan.jpg',
      encryptedStagingPath: staging.path,
      thumbnailStagingPath: '${tempDir.path}/orphan.jpg.part',
    );

    expect(journal.listByStatus(TransactionStatus.prepared), hasLength(1));
    expect(staging.existsSync(), isTrue);

    final report = await BootRecoveryService(journal).run();

    expect(report.rolledBackCount, 1);
    expect(staging.existsSync(), isFalse);
    expect(target.existsSync(), isFalse);
    expect(journal.listByStatus(TransactionStatus.prepared), isEmpty);
    expect(
      journal.listByStatus(TransactionStatus.rolledBack),
      hasLength(1),
    );
  });

  test('commit marks journal committed and writes asset manifest', () {
    journal.prepare(
      transactionId: 'txn-ok',
      assetFingerprint: 'fp_ok',
      encryptedTargetPath: '${tempDir.path}/ok.seal',
      thumbnailTargetPath: '${tempDir.path}/ok.jpg',
      encryptedStagingPath: '${tempDir.path}/ok.seal.part',
      thumbnailStagingPath: '${tempDir.path}/ok.jpg.part',
    );

    journal.commit(
      transactionId: 'txn-ok',
      assetFingerprint: 'fp_ok',
      encryptedPath: '${tempDir.path}/ok.seal',
      thumbnailPath: '${tempDir.path}/ok.jpg',
      byteLength: 42,
      mimeType: 'image/jpeg',
    );

    expect(journal.listByStatus(TransactionStatus.committed), hasLength(1));

    final manifest = factory.database.select(
      'SELECT byte_length FROM asset_manifest WHERE asset_fingerprint = ?',
      ['fp_ok'],
    );
    expect(manifest, hasLength(1));
    expect(manifest.first['byte_length'], 42);
  });
}
