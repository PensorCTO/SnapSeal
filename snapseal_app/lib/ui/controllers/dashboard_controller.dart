import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../domain/services/vault_service.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, List<ArchiveItem>>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<List<ArchiveItem>> {
  @override
  Future<List<ArchiveItem>> build() async {
    final items = await ref.read(vaultDatabaseProvider).listArchiveItems();
    unawaited(_runBackgroundPendingSync());
    return items;
  }

  /// Best-effort: does not block the initial list; refreshes if anything syncs.
  Future<void> _runBackgroundPendingSync() async {
    final pending = await ref.read(vaultDatabaseProvider).listPendingArchiveItems();
    if (pending.isEmpty) {
      return;
    }

    final vault = ref.read(vaultServiceProvider);
    var changed = false;
    for (final item in pending) {
      try {
        final cleared = await vault.retryPendingRemoteSync(item.assetFingerprint);
        if (cleared) {
          changed = true;
        }
      } catch (_) {
        // Intentionally ignored: dashboard must load even when sync fails.
      }
    }

    if (changed) {
      ref.invalidateSelf();
    }
  }

  Future<void> burnLocalWallet() async {
    await ref.read(vaultServiceProvider).burnLocalWallet();
    state = const AsyncData([]);
  }
}
