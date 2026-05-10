import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/vault_database.dart';
import '../../data/models/archive_item.dart';
import '../../domain/services/vault_service.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, List<ArchiveItem>>(
      DashboardController.new,
    );

final pendingSyncCoordinatorProvider = Provider<PendingSyncCoordinator>(
  (ref) => PendingSyncCoordinator(),
);

class PendingSyncCoordinator {
  Future<void>? _inFlight;

  Future<void> run(Future<void> Function() action) {
    final inFlight = _inFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<void>();
    _inFlight = completer.future;

    () async {
      try {
        await action();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      } finally {
        if (identical(_inFlight, completer.future)) {
          _inFlight = null;
        }
      }
    }();

    return completer.future;
  }
}

class DashboardController extends AsyncNotifier<List<ArchiveItem>> {
  @override
  Future<List<ArchiveItem>> build() async {
    return ref.read(vaultDatabaseProvider).listArchiveItems();
  }

  /// Explicit background trigger invoked by the view lifecycle.
  Future<void> syncPendingInBackground() async {
    final coordinator = ref.read(pendingSyncCoordinatorProvider);
    await coordinator.run(() async {
      final pending =
          await ref.read(vaultDatabaseProvider).listPendingArchiveItems();
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
          // Intentionally ignored: dashboard must stay responsive during sync attempts.
        }
      }

      if (changed) {
        final refreshed = await ref.read(vaultDatabaseProvider).listArchiveItems();
        state = AsyncData(refreshed);
      }
    });
  }

  Future<void> burnLocalWallet() async {
    await ref.read(vaultServiceProvider).burnLocalWallet();
    state = const AsyncData([]);
  }
}
