import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../models/archive_item.dart';

final archiveDatabaseProvider = Provider<ArchiveDatabase>(
  (ref) => getIt<ArchiveDatabase>(),
);

class ArchiveDatabase {
  Future<void> ensureOpen() async {}

  Future<void> upsertArchiveItem(ArchiveItem item) async {
    throw UnsupportedError('Local archive database is mobile-only.');
  }

  Future<List<ArchiveItem>> listArchiveItems() async => const [];

  Future<List<ArchiveItem>> listPendingArchiveItems() async => const [];

  Future<ArchiveItem?> findArchiveItem(String assetFingerprint) async => null;

  Future<void> setPendingSync({
    required String assetFingerprint,
    required bool pendingSync,
  }) async {}

  Future<void> markSyncSucceeded({
    required String assetFingerprint,
    String? chainTxHash,
  }) async {}

  Future<void> markSyncDeferred({
    required String assetFingerprint,
    required DateTime nextRetryAt,
  }) async {}

  Future<void> updateArchiveMetadata({
    required String assetFingerprint,
    required String? title,
    required String? description,
  }) async {}

  Future<void> deleteAll() async {}

  Future<int> deleteArchiveItem(String assetFingerprint) async => 0;

  Future<int> sumLocalByteLength() async => 0;
}
